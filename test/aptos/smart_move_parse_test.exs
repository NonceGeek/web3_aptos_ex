defmodule Web3AptosEx.SmartMoveParseTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "test parse function " do
    assert [
             "#[view]\npublic fun get_message(addr: address): string::String acquires MessageHolder {\n        assert!(exists<MessageHolder>(addr), error::not_found(ENO_MESSAGE));\n        borrow_global<MessageHolder>(addr).message\n}\n",
             "public entry fun set_message(account: signer, message: string::String)\n    acquires MessageHolder {\n        let account_addr = signer::address_of(&account);\n        if (!exists<MessageHolder>(account_addr)) {\n            move_to(&account, MessageHolder {                message,                message_change_events: account::new_event_handle<MessageChangeEvent>(&account),})\n        } else {\n            let old_message_holder = borrow_global_mut<MessageHolder>(account_addr);\n            let from_message = old_message_holder.message;\n            event::emit_event(&mut old_message_holder.message_change_events, MessageChangeEvent {                from_message,                to_message: copy message,});\n            old_message_holder.message = message;\n}\n}\n",
             "#[test(account = @0x1)]\npublic entry fun sender_can_set_message(account: signer) acquires MessageHolder {\n        let addr = signer::address_of(&account);\n        aptos_framework::account::create_account_for_test(addr);\n        set_message(account,  string::utf8(b\"Hello, Blockchain\"));\n        assert!(\n          get_message(addr) == string::utf8(b\"Hello, Blockchain\"),\n          ENO_MESSAGE\n        );\n}\n"
           ] ==
             Web3AptosEx.Aptos.SmartContractParser.parse_fun(move_file_content())

    assert [
             "struct MessageChangeEvent has drop, store {\n        from_message: string::String,\n        to_message: string::String,\n}\n"
           ] == Web3AptosEx.Aptos.SmartContractParser.parse_event(move_file_content())

    assert [
             "struct MessageHolder has key {\n        message: string::String,\n        message_change_events: event::EventHandle<MessageChangeEvent>,\n}\n"
           ] == Web3AptosEx.Aptos.SmartContractParser.parse_struct(move_file_content())
  end

  test "test parse smart move" do
    # parse struct
    check_parse(
      {:ok,
       [
         comment: ['// nihao'],
         comment: ['/* hello', '....', 'kkkk */'],
         struct: ['struct Box<T> has key { items: vector<T> }'],
         struct: ['struct Hello has key{', '    items: vector<string>', '}'],
         struct: [
           '#[resource_group_member(group = aptos_framework::object::ObjectGroup)]',
           'struct Weapon has key {',
           '     attack: u64,',
           '     gem: Option<Object<Gem>>,',
           '     weapon_type: String,',
           '     weight: u64,',
           '}'
         ]
       ]},
      """
      // nihao
      /* hello
      ....
      kkkk */
       struct Box<T> has key { items: vector<T> }
       struct Hello has key{
          items: vector<string>
       }
       #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
       struct Weapon has key {
           attack: u64,
           gem: Option<Object<Gem>>,
           weapon_type: String,
           weight: u64,
       }
      """
    )

    # parse event
    check_parse(
      {:ok,
       [
         event: [
           'struct WeaponEvent has key {',
           '       attack: u64,',
           '       gem: Option<Object<Gem>>,',
           '       weapon_type: String,',
           '       weight: u64,',
           '}'
         ],
         event: [
           '#[view]',
           'struct WeaponEvent has key {',
           '       attack: u64,',
           '       gem: Option<Object<Gem>>,',
           '       weapon_type: String,',
           '       weight: u64,',
           '}'
         ]
       ]},
      """
          struct WeaponEvent has key {
             attack: u64,
             gem: Option<Object<Gem>>,
             weapon_type: String,
             weight: u64,
         }
         #[view]
      struct WeaponEvent has key {
             attack: u64,
             gem: Option<Object<Gem>>,
             weapon_type: String,
             weight: u64,
         }
      """
    )

    # parse function
    check_parse(
      {:ok,
       [
         comment: ['// nihao'],
         comment: ['/* hello', '....', 'kkkk */'],
         comment: ['//:!:>resource'],
         struct: ['struct Box<T> has key { items: vector<T> }'],
         struct: ['struct Hello has key{', '    items: vector<string>', '}'],
         function: [
           '#[view]',
           'public fun get_message(addr: address): string::String acquires MessageHolder {',
           '  assert!(exists<MessageHolder>(addr), error::not_found(ENO_MESSAGE));',
           '  borrow_global<MessageHolder>(addr).message',
           '}'
         ],
         function: ['fun zero(): u64 { 0 }'],
         function: ['public fun zero1(): u64 { 0 }'],
         function: [
           'public fun store_two<Item1: store, Item2: store>(',
           '      addr: address,',
           '      item1: Item1,',
           '      item2: Item2,',
           '  ) acquires Balance, Box {',
           '      let balance = borrow_global_mut<Balance>(addr); // acquires needed',
           '      balance.value = balance.value - 2;',
           '      let box1 = borrow_global_mut<Box<Item1>>(addr); // acquires needed',
           '      vector::push_back(&mut box1.items, item1);',
           '      let box2 = borrow_global_mut<Box<Item2>>(addr); // acquires needed',
           '      vector::push_back(&mut box2.items, item2);',
           '}'
         ],
         function: [
           'public fun new1(center: Point, radius: u64): Circle {',
           '  Circle {',
           '      center,',
           '      radius',
           '}',
           '}'
         ],
         function: [
           'fun example_destroy_baz() {',
           '  let baz = Baz {};',
           '  let Baz {} = baz;',
           '}'
         ],
         function: [
           'entry fun mint_hero(',
           '  account: &signer,',
           '  description: String,',
           '  gender: String,',
           '  name: String,',
           '  race: String,',
           '  uri: String,',
           ') acquires OnChainConfig {',
           '  create_hero(account, description, gender, name, race, uri);',
           '}'
         ],
         function: [
           'inline fun get_hero(creator: &address, collection: &String, name: &String): (Object<Hero>, &Hero) {',
           '  let token_address = token::create_token_address(',
           '      creator,',
           '      collection,',
           '      name,',
           '  );',
           '  (object::address_to_object<Hero>(token_address), borrow_global<Hero>(token_address))',
           '}'
         ]
       ]},
      """
      // nihao
      /* hello
      ....
      kkkk */
      //:!:>resource
       struct Box<T> has key { items: vector<T> }
       struct Hello has key{
          items: vector<string>
       }
      #[view]
      public fun get_message(addr: address): string::String acquires MessageHolder {
        assert!(exists<MessageHolder>(addr), error::not_found(ENO_MESSAGE));
        borrow_global<MessageHolder>(addr).message
      }
      fun zero(): u64 { 0 }
      public fun zero1(): u64 { 0 }
      public fun store_two<Item1: store, Item2: store>(
            addr: address,
            item1: Item1,
            item2: Item2,
        ) acquires Balance, Box {
            let balance = borrow_global_mut<Balance>(addr); // acquires needed
            balance.value = balance.value - 2;
            let box1 = borrow_global_mut<Box<Item1>>(addr); // acquires needed
            vector::push_back(&mut box1.items, item1);
            let box2 = borrow_global_mut<Box<Item2>>(addr); // acquires needed
            vector::push_back(&mut box2.items, item2);
      }
      public fun new1(center: Point, radius: u64): Circle {
        Circle {
            center,
            radius
        }
      }
      fun example_destroy_baz() {
        let baz = Baz {};
        let Baz {} = baz;
      }
      entry fun mint_hero(
        account: &signer,
        description: String,
        gender: String,
        name: String,
        race: String,
        uri: String,
      ) acquires OnChainConfig {
        create_hero(account, description, gender, name, race, uri);
      }
      inline fun get_hero(creator: &address, collection: &String, name: &String): (Object<Hero>, &Hero) {
        let token_address = token::create_token_address(
            creator,
            collection,
            name,
        );
        (object::address_to_object<Hero>(token_address), borrow_global<Hero>(token_address))
      }
      """
    )

    check_parse(
      {:ok,
       [
         function: [
           'public fun create_weapon(',
           '        creator: &signer,',
           '        attack: u64,',
           '        description: String,',
           '        name: String,',
           '        uri: String,',
           '        weapon_type: String,',
           '        weight: u64,',
           '    ): Object<Weapon> acquires OnChainConfig {',
           '        let constructor_ref = create(creator, description, name, uri);',
           '        let token_signer = object::generate_signer(&constructor_ref);',
           [
             '        let weapon = Weapon {',
             '            attack,',
             '            gem: option::none(),',
             '            weapon_type,',
             '            weight,',
             '};'
           ],
           '        move_to(&token_signer, weapon);',
           '        object::address_to_object(signer::address_of(&token_signer))',
           '}'
         ]
       ]},
      """
      public fun create_weapon(
              creator: &signer,
              attack: u64,
              description: String,
              name: String,
              uri: String,
              weapon_type: String,
              weight: u64,
          ): Object<Weapon> acquires OnChainConfig {
              let constructor_ref = create(creator, description, name, uri);
              let token_signer = object::generate_signer(&constructor_ref);

              let weapon = Weapon {
                  attack,
                  gem: option::none(),
                  weapon_type,
                  weight,
              };
              move_to(&token_signer, weapon);

              object::address_to_object(signer::address_of(&token_signer))
          }
      """
    )

    check_parse(
      {:ok,
       [
         function: [
           'inline fun get_hero(creator: &address, collection: &String, name: &String): (Object<Hero>, &Hero) {',
           '        let token_address = token::create_token_address(',
           '            creator,',
           '            collection,',
           '            name,',
           '        );',
           '        (object::address_to_object<Hero>(token_address), borrow_global<Hero>(token_address))',
           '}'
         ]
       ]},
      """
       inline fun get_hero(creator: &address, collection: &String, name: &String): (Object<Hero>, &Hero) {
              let token_address = token::create_token_address(
                  creator,
                  collection,
                  name,
              );
              (object::address_to_object<Hero>(token_address), borrow_global<Hero>(token_address))
          }
      """
    )

    check_parse(
      {:ok,
       [
         function: [
           '#[view]',
           'fun view_object<T: key>(obj: Object<T>): String acquires Armor, Gem, Hero, Shield, Weapon {',
           '        let token_address = object::object_address(&obj);',
           '        if (exists<Armor>(token_address)) {',
           '            string_utils::to_string(borrow_global<Armor>(token_address))',
           '        } else if (exists<Gem>(token_address)) {',
           '            string_utils::to_string(borrow_global<Gem>(token_address))',
           '        } else if (exists<Hero>(token_address)) {',
           '            string_utils::to_string(borrow_global<Hero>(token_address))',
           '        } else if (exists<Shield>(token_address)) {',
           '            string_utils::to_string(borrow_global<Shield>(token_address))',
           '        } else if (exists<Weapon>(token_address)) {',
           '            string_utils::to_string(borrow_global<Weapon>(token_address))',
           '        } else {',
           '            abort EINVALID_TYPE',
           '}',
           '}'
         ]
       ]},
      """
         #[view]
          fun view_object<T: key>(obj: Object<T>): String acquires Armor, Gem, Hero, Shield, Weapon {
              let token_address = object::object_address(&obj);
              if (exists<Armor>(token_address)) {
                  string_utils::to_string(borrow_global<Armor>(token_address))
              } else if (exists<Gem>(token_address)) {
                  string_utils::to_string(borrow_global<Gem>(token_address))
              } else if (exists<Hero>(token_address)) {
                  string_utils::to_string(borrow_global<Hero>(token_address))
              } else if (exists<Shield>(token_address)) {
                  string_utils::to_string(borrow_global<Shield>(token_address))
              } else if (exists<Weapon>(token_address)) {
                  string_utils::to_string(borrow_global<Weapon>(token_address))
              } else {
                  abort EINVALID_TYPE
              }
          }
      """
    )

    check_parse(
      {:ok,
       [
         function: [
           'public entry fun set_message(account: signer, message: string::String)',
           '    acquires MessageHolder {',
           '        let account_addr = signer::address_of(&account);',
           '        if (!exists<MessageHolder>(account_addr)) {',
           [
             '            move_to(&account, MessageHolder {',
             '                message,',
             '                message_change_events: account::new_event_handle<MessageChangeEvent>(&account),',
             '})'
           ],
           '        } else {',
           '            let old_message_holder = borrow_global_mut<MessageHolder>(account_addr);',
           '            let from_message = old_message_holder.message;',
           [
             '            event::emit_event(&mut old_message_holder.message_change_events, MessageChangeEvent {',
             '                from_message,',
             '                to_message: copy message,',
             '});'
           ],
           '            old_message_holder.message = message;',
           '}',
           '}'
         ]
       ]},
      """
       public entry fun set_message(account: signer, message: string::String)
          acquires MessageHolder {
              let account_addr = signer::address_of(&account);
              if (!exists<MessageHolder>(account_addr)) {
                  move_to(&account, MessageHolder {
                      message,
                      message_change_events: account::new_event_handle<MessageChangeEvent>(&account),
                  })
              } else {
                  let old_message_holder = borrow_global_mut<MessageHolder>(account_addr);
                  let from_message = old_message_holder.message;
                  event::emit_event(&mut old_message_holder.message_change_events, MessageChangeEvent {
                      from_message,
                      to_message: copy message,
                  });
                  old_message_holder.message = message;
              }
          }
      """
    )

    check_parse(
      {:ok,
       [
         function: ['fun foo() {', '    native public enpty();', '    while (true) { }', '}'],
         function: [
           'fun sum(n: u64): u64 {',
           '  let sum = 0;',
           '  let i = 1;',
           ['  while (i <= n) {', '      sum = sum + i;', '      i = i + 1', '};'],
           '  sum',
           '}'
         ]
       ]},
      """
      fun foo() {
          native public enpty();
          while (true) { }
      }
      fun sum(n: u64): u64 {
        let sum = 0;
        let i = 1;
        while (i <= n) {
            sum = sum + i;
            i = i + 1
        };

        sum
      }

      """
    )

    check_parse(
      {:ok,
       [
         module: ['module hero::hero {'],
         use: ['use std::error;'],
         use: ['use std::option::{Self, Option};'],
         use: ['use std::signer;'],
         use: ['use std::string::{Self, String};'],
         use: ['use aptos_framework::object::{Self, ConstructorRef, Object};'],
         use: ['use aptos_token_objects::collection;'],
         use: ['use aptos_token_objects::token;'],
         use: ['use aptos_std::string_utils;'],
         const: ['const ENOT_A_HERO: u64 = 1;'],
         const: ['const ENOT_A_WEAPON: u64 = 2;'],
         const: ['const ENOT_A_GEM: u64 = 3;'],
         const: ['const ENOT_CREATOR: u64 = 4;'],
         const: ['const EINVALID_WEAPON_UNEQUIP: u64 = 5;'],
         const: ['const EINVALID_GEM_UNEQUIP: u64 = 6;'],
         const: ['const EINVALID_TYPE: u64 = 7;'],
         struct: ['struct OnChainConfig has key {', '        collection: String,', '}'],
         struct: [
           '#[resource_group_member(group = aptos_framework::object::ObjectGroup)]',
           'struct Hero has key {',
           '        armor: Option<Object<Armor>>,',
           '        gender: String,',
           '        race: String,',
           '        shield: Option<Object<Shield>>,',
           '        weapon: Option<Object<Weapon>>,',
           '        mutator_ref: token::MutatorRef,',
           '}'
         ],
         struct: [
           '#[resource_group_member(group = aptos_framework::object::ObjectGroup)]',
           'struct Armor has key {',
           '        defense: u64,',
           '        gem: Option<Object<Gem>>,',
           '        weight: u64,',
           '}'
         ],
         struct: [
           '#[resource_group_member(group = aptos_framework::object::ObjectGroup)]',
           'struct Gem has key {',
           '        attack_modifier: u64,',
           '        defense_modifier: u64,',
           '        magic_attribute: String,',
           '}'
         ],
         struct: [
           '#[resource_group_member(group = aptos_framework::object::ObjectGroup)]',
           'struct Shield has key {',
           '        defense: u64,',
           '        gem: Option<Object<Gem>>,',
           '        weight: u64,',
           '}'
         ],
         struct: [
           '#[resource_group_member(group = aptos_framework::object::ObjectGroup)]',
           'struct Weapon has key {',
           '        attack: u64,',
           '        gem: Option<Object<Gem>>,',
           '        weapon_type: String,',
           '        weight: u64,',
           '}'
         ],
         function: [
           'fun init_module(account: &signer) {',
           '        let collection = string::utf8(b"Hero Quest!");',
           '        collection::create_unlimited_collection(',
           '            account,',
           '            string::utf8(b"collection description"),',
           '            collection,',
           '            option::none(),',
           '            string::utf8(b"collection uri"),',
           '        );',
           ['        let on_chain_config = OnChainConfig {', '            collection,', '};'],
           '        move_to(account, on_chain_config);',
           '}'
         ],
         function: [
           'fun create(',
           '        creator: &signer,',
           '        description: String,',
           '        name: String,',
           '        uri: String,',
           '    ): ConstructorRef acquires OnChainConfig {',
           '        let on_chain_config = borrow_global<OnChainConfig>(signer::address_of(creator));',
           '        token::create_named_token(',
           '            creator,',
           '            on_chain_config.collection,',
           '            description,',
           '            name,',
           '            option::none(),',
           '            uri,',
           '        )',
           '}'
         ],
         comment: ['    // Creation methods'],
         function: [
           'public fun create_hero(',
           '        creator: &signer,',
           '        description: String,',
           '        gender: String,',
           '        name: String,',
           '        race: String,',
           '        uri: String,',
           '    ): Object<Hero> acquires OnChainConfig {',
           '        let constructor_ref = create(creator, description, name, uri);',
           '        let token_signer = object::generate_signer(&constructor_ref);',
           [
             '        let hero = Hero {',
             '            armor: option::none(),',
             '            gender,',
             '            race,',
             '            shield: option::none(),',
             '            weapon: option::none(),',
             '            mutator_ref: token::generate_mutator_ref(&constructor_ref),',
             '};'
           ],
           '        move_to(&token_signer, hero);',
           '        object::address_to_object(signer::address_of(&token_signer))',
           '}'
         ],
         function: [
           'public fun create_weapon(',
           '        creator: &signer,',
           '        attack: u64,',
           '        description: String,',
           '        name: String,',
           '        uri: String,',
           '        weapon_type: String,',
           '        weight: u64,',
           '    ): Object<Weapon> acquires OnChainConfig {',
           '        let constructor_ref = create(creator, description, name, uri);',
           '        let token_signer = object::generate_signer(&constructor_ref);',
           [
             '        let weapon = Weapon {',
             '            attack,',
             '            gem: option::none(),',
             '            weapon_type,',
             '            weight,',
             '};'
           ],
           '        move_to(&token_signer, weapon);',
           '        object::address_to_object(signer::address_of(&token_signer))',
           '}'
         ],
         function: [
           'public fun create_gem(',
           '        creator: &signer,',
           '        attack_modifier: u64,',
           '        defense_modifier: u64,',
           '        description: String,',
           '        magic_attribute: String,',
           '        name: String,',
           '        uri: String,',
           '    ): Object<Gem> acquires OnChainConfig {',
           '        let constructor_ref = create(creator, description, name, uri);',
           '        let token_signer = object::generate_signer(&constructor_ref);',
           [
             '        let gem = Gem {',
             '            attack_modifier,',
             '            defense_modifier,',
             '            magic_attribute,',
             '};'
           ],
           '        move_to(&token_signer, gem);',
           '        object::address_to_object(signer::address_of(&token_signer))',
           '}'
         ],
         comment: ['    // Transfer wrappers'],
         function: [
           'public fun hero_equip_weapon(owner: &signer, hero: Object<Hero>, weapon: Object<Weapon>) acquires Hero {',
           '        let hero_obj = borrow_global_mut<Hero>(object::object_address(&hero));',
           '        option::fill(&mut hero_obj.weapon, weapon);',
           '        object::transfer_to_object(owner, weapon, hero);',
           '}'
         ],
         function: [
           'public fun hero_unequip_weapon(owner: &signer, hero: Object<Hero>, weapon: Object<Weapon>) acquires Hero {',
           '        let hero_obj = borrow_global_mut<Hero>(object::object_address(&hero));',
           '        let stored_weapon = option::extract(&mut hero_obj.weapon);',
           '        assert!(stored_weapon == weapon, error::not_found(EINVALID_WEAPON_UNEQUIP));',
           '        object::transfer(owner, weapon, signer::address_of(owner));',
           '}'
         ],
         function: [
           'public fun weapon_equip_gem(owner: &signer, weapon: Object<Weapon>, gem: Object<Gem>) acquires Weapon {',
           '        let weapon_obj = borrow_global_mut<Weapon>(object::object_address(&weapon));',
           '        option::fill(&mut weapon_obj.gem, gem);',
           '        object::transfer_to_object(owner, gem, weapon);',
           '}'
         ],
         function: [
           'public fun weapon_unequip_gem(owner: &signer, weapon: Object<Weapon>, gem: Object<Gem>) acquires Weapon {',
           '        let weapon_obj = borrow_global_mut<Weapon>(object::object_address(&weapon));',
           '        let stored_gem = option::extract(&mut weapon_obj.gem);',
           '        assert!(stored_gem == gem, error::not_found(EINVALID_GEM_UNEQUIP));',
           '        object::transfer(owner, gem, signer::address_of(owner));',
           '}'
         ],
         comment: ['    // Entry functions'],
         function: [
           'entry fun mint_hero(',
           '        account: &signer,',
           '        description: String,',
           '        gender: String,',
           '        name: String,',
           '        race: String,',
           '        uri: String,',
           '    ) acquires OnChainConfig {',
           '        create_hero(account, description, gender, name, race, uri);',
           '}'
         ],
         function: [
           'entry fun set_hero_description(',
           '        creator: &signer,',
           '        collection: String,',
           '        name: String,',
           '        description: String,',
           '    ) acquires Hero {',
           '        let (hero_obj, hero) = get_hero(',
           '            &signer::address_of(creator),',
           '            &collection,',
           '            &name,',
           '        );',
           '        let creator_addr = token::creator(hero_obj);',
           '        assert!(creator_addr == signer::address_of(creator), error::permission_denied(ENOT_CREATOR));',
           '        token::set_description(&hero.mutator_ref, description);',
           '}'
         ],
         comment: ['    // View functions'],
         function: [
           '#[view]',
           'fun view_hero(creator: address, collection: String, name: String): Hero acquires Hero {',
           '        let token_address = token::create_token_address(',
           '            &creator,',
           '            &collection,',
           '            &name,',
           '        );',
           '        move_from<Hero>(token_address)',
           '}'
         ],
         function: [
           '#[view]',
           'fun view_hero_by_object(hero_obj: Object<Hero>): Hero acquires Hero {',
           '        let token_address = object::object_address(&hero_obj);',
           '        move_from<Hero>(token_address)',
           '}'
         ],
         function: [
           '#[view]',
           'fun view_object<T: key>(obj: Object<T>): String acquires Armor, Gem, Hero, Shield, Weapon {',
           '        let token_address = object::object_address(&obj);',
           '        if (exists<Armor>(token_address)) {',
           '            string_utils::to_string(borrow_global<Armor>(token_address))',
           '        } else if (exists<Gem>(token_address)) {',
           '            string_utils::to_string(borrow_global<Gem>(token_address))',
           '        } else if (exists<Hero>(token_address)) {',
           '            string_utils::to_string(borrow_global<Hero>(token_address))',
           '        } else if (exists<Shield>(token_address)) {',
           '            string_utils::to_string(borrow_global<Shield>(token_address))',
           '        } else if (exists<Weapon>(token_address)) {',
           '            string_utils::to_string(borrow_global<Weapon>(token_address))',
           '        } else {',
           '            abort EINVALID_TYPE',
           '}',
           '}'
         ],
         function: [
           'inline fun get_hero(creator: &address, collection: &String, name: &String): (Object<Hero>, &Hero) {',
           '        let token_address = token::create_token_address(',
           '            creator,',
           '            collection,',
           '            name,',
           '        );',
           '        (object::address_to_object<Hero>(token_address), borrow_global<Hero>(token_address))',
           '}'
         ],
         function: [
           '#[test(account = @0x3)]',
           'fun test_hero_with_gem_weapon(account: &signer) acquires Hero, OnChainConfig, Weapon {',
           '        init_module(account);',
           '        let hero = create_hero(',
           '            account,',
           '            string::utf8(b"The best hero ever!"),',
           '            string::utf8(b"Male"),',
           '            string::utf8(b"Wukong"),',
           '            string::utf8(b"Monkey God"),',
           '            string::utf8(b""),',
           '        );',
           '        let weapon = create_weapon(',
           '            account,',
           '            32,',
           '            string::utf8(b"A magical staff!"),',
           '            string::utf8(b"Ruyi Jingu Bang"),',
           '            string::utf8(b""),',
           '            string::utf8(b"staff"),',
           '            15,',
           '        );',
           '        let gem = create_gem(',
           '            account,',
           '            32,',
           '            32,',
           '            string::utf8(b"Beautiful specimen!"),',
           '            string::utf8(b"earth"),',
           '            string::utf8(b"jade"),',
           '            string::utf8(b""),',
           '        );',
           '        let account_address = signer::address_of(account);',
           '        assert!(object::is_owner(hero, account_address), 0);',
           '        assert!(object::is_owner(weapon, account_address), 1);',
           '        assert!(object::is_owner(gem, account_address), 2);',
           '        hero_equip_weapon(account, hero, weapon);',
           '        assert!(object::is_owner(hero, account_address), 3);',
           '        assert!(object::is_owner(weapon, object::object_address(&hero)), 4);',
           '        assert!(object::is_owner(gem, account_address), 5);',
           '        weapon_equip_gem(account, weapon, gem);',
           '        assert!(object::is_owner(hero, account_address), 6);',
           '        assert!(object::is_owner(weapon, object::object_address(&hero)), 7);',
           '        assert!(object::is_owner(gem, object::object_address(&weapon)), 8);',
           '        hero_unequip_weapon(account, hero, weapon);',
           '        assert!(object::is_owner(hero, account_address), 9);',
           '        assert!(object::is_owner(weapon, account_address), 10);',
           '        assert!(object::is_owner(gem, object::object_address(&weapon)), 11);',
           '        weapon_unequip_gem(account, weapon, gem);',
           '        assert!(object::is_owner(hero, account_address), 12);',
           '        assert!(object::is_owner(weapon, account_address), 13);',
           '        assert!(object::is_owner(gem, account_address), 14);',
           '}'
         ],
         module_end: ['}']
       ]},
      aptos_hero()
    )

    check_parse(
      {:ok,
       [
         module: ['  module hello_blockchain::message {'],
         use: ['use std::error;'],
         use: ['use std::signer;'],
         use: ['use std::string;'],
         use: ['use aptos_framework::account;'],
         use: ['use aptos_framework::event;'],
         comment: ['//:!:>resource'],
         struct: [
           'struct MessageHolder has key {',
           '        message: string::String,',
           '        message_change_events: event::EventHandle<MessageChangeEvent>,',
           '}'
         ],
         comment: ['//<:!:resource'],
         event: [
           'struct MessageChangeEvent has drop, store {',
           '        from_message: string::String,',
           '        to_message: string::String,',
           '}'
         ],
         comment: ['    /// There is no message present'],
         const: ['const ENO_MESSAGE: u64 = 0;'],
         function: [
           '#[view]',
           'public fun get_message(addr: address): string::String acquires MessageHolder {',
           '        assert!(exists<MessageHolder>(addr), error::not_found(ENO_MESSAGE));',
           '        borrow_global<MessageHolder>(addr).message',
           '}'
         ],
         function: [
           'public entry fun set_message(account: signer, message: string::String)',
           '    acquires MessageHolder {',
           '        let account_addr = signer::address_of(&account);',
           '        if (!exists<MessageHolder>(account_addr)) {',
           [
             '            move_to(&account, MessageHolder {',
             '                message,',
             '                message_change_events: account::new_event_handle<MessageChangeEvent>(&account),',
             '})'
           ],
           '        } else {',
           '            let old_message_holder = borrow_global_mut<MessageHolder>(account_addr);',
           '            let from_message = old_message_holder.message;',
           [
             '            event::emit_event(&mut old_message_holder.message_change_events, MessageChangeEvent {',
             '                from_message,',
             '                to_message: copy message,',
             '});'
           ],
           '            old_message_holder.message = message;',
           '}',
           '}'
         ],
         function: [
           '#[test(account = @0x1)]',
           'public entry fun sender_can_set_message(account: signer) acquires MessageHolder {',
           '        let addr = signer::address_of(&account);',
           '        aptos_framework::account::create_account_for_test(addr);',
           '        set_message(account,  string::utf8(b"Hello, Blockchain"));',
           '        assert!(',
           '          get_message(addr) == string::utf8(b"Hello, Blockchain"),',
           '          ENO_MESSAGE',
           '        );',
           '}'
         ],
         module_end: ['}']
       ]},
      move_file_content()
    )

    check_parse(
      {:ok,
       [
         module: ['module 0x8675309::M {'],
         struct: ['struct S has copy, drop { f: u64, g: u64 }'],
         function: ['fun id<T>(r: &T): &T {', '       r', '}'],
         function: ['fun id_mut<T>(r: &mut T): &mut T {', '       r', '}'],
         function: [
           'fun t0(cond: bool) {',
           '       let s = S { f: 0, g: 0 };',
           '       let f;',
           '       if (cond) f = &s.f else f = &s.g;',
           '       *f;',
           '       s = S { f: 0, g: 0 };',
           '       s;',
           '}'
         ],
         function: [
           'fun t1(cond: bool, other: &mut S) {',
           '       let s = S { f: 0, g: 0 };',
           '       let f;',
           '       if (cond) f = &mut s.f else f = &mut other.f;',
           '       *f;',
           '       s = S { f: 0, g: 0 };',
           '       s;',
           '}'
         ],
         function: [
           'fun t2(cond: bool, other: &mut S) {',
           '       let s = S { f: 0, g: 0 };',
           '       let f;',
           '       if (cond) f = &mut s else f = other;',
           '       *f;',
           '       s = S { f: 0, g: 0 };',
           '       s;',
           '}'
         ],
         function: [
           'fun t3(cond: bool, other: &mut S) {',
           '       let s = S { f: 0, g: 0 };',
           '       let f;',
           '       if (cond) f = id_mut(&mut s) else f = other;',
           '       *f;',
           '       s = S { f: 0, g: 0 };',
           '       s;',
           '}'
         ],
         function: [
           'fun t4(cond: bool) {',
           '       let s = S { f: 0, g: 0 };',
           '       let f = &s.f;',
           '       if (cond) s = S { f: 0, g: 0 } else { *f; };',
           '       s;',
           '}'
         ],
         module_end: ['}']
       ]},
      local_compo()
    )

    check_parse(
      {:ok,
       [
         script: ['script {'],
         use: ['use std::debug;'],
         friend: ['friend 0x42::another_test;'],
         const: ['const ONE: u64 = 1;'],
         function: [
           'fun main(x: u64) {',
           '        let sum = x + ONE;',
           '        debug::print(&sum)',
           '}'
         ],
         module_end: ['}']
       ]},
      """
      script {
          use std::debug;
          friend 0x42::another_test;
          const ONE: u64 = 1;

          fun main(x: u64) {
              let sum = x + ONE;
              debug::print(&sum)
          }
      }
      """
    )
  end

  defp check_parse(expect, str) do
    {:ok, tokens, _} = :smart_move_leex.string(String.to_charlist(str))
    # IO.puts(" ===>>>> #{inspect(tokens)}", limit: :infinity)
    # IO.inspect(tokens, limit: :infinity)
    res = :smart_move_yecc.parse(tokens)
    # IO.inspect(res, limit: :infinity)
    assert expect == res
  end

  defp move_file_content do
    """
      module hello_blockchain::message {
        use std::error;
        use std::signer;
        use std::string;
        use aptos_framework::account;
        use aptos_framework::event;

    //:!:>resource
        struct MessageHolder has key {
            message: string::String,
            message_change_events: event::EventHandle<MessageChangeEvent>,
        }
    //<:!:resource

        struct MessageChangeEvent has drop, store {
            from_message: string::String,
            to_message: string::String,
        }

        /// There is no message present
        const ENO_MESSAGE: u64 = 0;

        #[view]
        public fun get_message(addr: address): string::String acquires MessageHolder {
            assert!(exists<MessageHolder>(addr), error::not_found(ENO_MESSAGE));
            borrow_global<MessageHolder>(addr).message
        }

        public entry fun set_message(account: signer, message: string::String)
        acquires MessageHolder {
            let account_addr = signer::address_of(&account);
            if (!exists<MessageHolder>(account_addr)) {
                move_to(&account, MessageHolder {
                    message,
                    message_change_events: account::new_event_handle<MessageChangeEvent>(&account),
                })
            } else {
                let old_message_holder = borrow_global_mut<MessageHolder>(account_addr);
                let from_message = old_message_holder.message;
                event::emit_event(&mut old_message_holder.message_change_events, MessageChangeEvent {
                    from_message,
                    to_message: copy message,
                });
                old_message_holder.message = message;
            }
        }

        #[test(account = @0x1)]
        public entry fun sender_can_set_message(account: signer) acquires MessageHolder {
            let addr = signer::address_of(&account);
            aptos_framework::account::create_account_for_test(addr);
            set_message(account,  string::utf8(b"Hello, Blockchain"));

            assert!(
              get_message(addr) == string::utf8(b"Hello, Blockchain"),
              ENO_MESSAGE
            );
        }
    }
    """
  end

  defp aptos_hero() do
    """
    module hero::hero {
        use std::error;
        use std::option::{Self, Option};
        use std::signer;
        use std::string::{Self, String};

        use aptos_framework::object::{Self, ConstructorRef, Object};

        use aptos_token_objects::collection;
        use aptos_token_objects::token;
        use aptos_std::string_utils;

        const ENOT_A_HERO: u64 = 1;
        const ENOT_A_WEAPON: u64 = 2;
        const ENOT_A_GEM: u64 = 3;
        const ENOT_CREATOR: u64 = 4;
        const EINVALID_WEAPON_UNEQUIP: u64 = 5;
        const EINVALID_GEM_UNEQUIP: u64 = 6;
        const EINVALID_TYPE: u64 = 7;

        struct OnChainConfig has key {
            collection: String,
        }

        #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
        struct Hero has key {
            armor: Option<Object<Armor>>,
            gender: String,
            race: String,
            shield: Option<Object<Shield>>,
            weapon: Option<Object<Weapon>>,
            mutator_ref: token::MutatorRef,
        }

        #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
        struct Armor has key {
            defense: u64,
            gem: Option<Object<Gem>>,
            weight: u64,
        }

        #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
        struct Gem has key {
            attack_modifier: u64,
            defense_modifier: u64,
            magic_attribute: String,
        }

        #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
        struct Shield has key {
            defense: u64,
            gem: Option<Object<Gem>>,
            weight: u64,
        }

        #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
        struct Weapon has key {
            attack: u64,
            gem: Option<Object<Gem>>,
            weapon_type: String,
            weight: u64,
        }

        fun init_module(account: &signer) {
            let collection = string::utf8(b"Hero Quest!");
            collection::create_unlimited_collection(
                account,
                string::utf8(b"collection description"),
                collection,
                option::none(),
                string::utf8(b"collection uri"),
            );

            let on_chain_config = OnChainConfig {
                collection,
            };
            move_to(account, on_chain_config);
        }

        fun create(
            creator: &signer,
            description: String,
            name: String,
            uri: String,
        ): ConstructorRef acquires OnChainConfig {
            let on_chain_config = borrow_global<OnChainConfig>(signer::address_of(creator));
            token::create_named_token(
                creator,
                on_chain_config.collection,
                description,
                name,
                option::none(),
                uri,
            )
        }

        // Creation methods

        public fun create_hero(
            creator: &signer,
            description: String,
            gender: String,
            name: String,
            race: String,
            uri: String,
        ): Object<Hero> acquires OnChainConfig {
            let constructor_ref = create(creator, description, name, uri);
            let token_signer = object::generate_signer(&constructor_ref);

            let hero = Hero {
                armor: option::none(),
                gender,
                race,
                shield: option::none(),
                weapon: option::none(),
                mutator_ref: token::generate_mutator_ref(&constructor_ref),
            };
            move_to(&token_signer, hero);

            object::address_to_object(signer::address_of(&token_signer))
        }

        public fun create_weapon(
            creator: &signer,
            attack: u64,
            description: String,
            name: String,
            uri: String,
            weapon_type: String,
            weight: u64,
        ): Object<Weapon> acquires OnChainConfig {
            let constructor_ref = create(creator, description, name, uri);
            let token_signer = object::generate_signer(&constructor_ref);

            let weapon = Weapon {
                attack,
                gem: option::none(),
                weapon_type,
                weight,
            };
            move_to(&token_signer, weapon);

            object::address_to_object(signer::address_of(&token_signer))
        }

        public fun create_gem(
            creator: &signer,
            attack_modifier: u64,
            defense_modifier: u64,
            description: String,
            magic_attribute: String,
            name: String,
            uri: String,
        ): Object<Gem> acquires OnChainConfig {
            let constructor_ref = create(creator, description, name, uri);
            let token_signer = object::generate_signer(&constructor_ref);

            let gem = Gem {
                attack_modifier,
                defense_modifier,
                magic_attribute,
            };
            move_to(&token_signer, gem);

            object::address_to_object(signer::address_of(&token_signer))
        }

        // Transfer wrappers

        public fun hero_equip_weapon(owner: &signer, hero: Object<Hero>, weapon: Object<Weapon>) acquires Hero {
            let hero_obj = borrow_global_mut<Hero>(object::object_address(&hero));
            option::fill(&mut hero_obj.weapon, weapon);
            object::transfer_to_object(owner, weapon, hero);
        }

        public fun hero_unequip_weapon(owner: &signer, hero: Object<Hero>, weapon: Object<Weapon>) acquires Hero {
            let hero_obj = borrow_global_mut<Hero>(object::object_address(&hero));
            let stored_weapon = option::extract(&mut hero_obj.weapon);
            assert!(stored_weapon == weapon, error::not_found(EINVALID_WEAPON_UNEQUIP));
            object::transfer(owner, weapon, signer::address_of(owner));
        }

        public fun weapon_equip_gem(owner: &signer, weapon: Object<Weapon>, gem: Object<Gem>) acquires Weapon {
            let weapon_obj = borrow_global_mut<Weapon>(object::object_address(&weapon));
            option::fill(&mut weapon_obj.gem, gem);
            object::transfer_to_object(owner, gem, weapon);
        }

        public fun weapon_unequip_gem(owner: &signer, weapon: Object<Weapon>, gem: Object<Gem>) acquires Weapon {
            let weapon_obj = borrow_global_mut<Weapon>(object::object_address(&weapon));
            let stored_gem = option::extract(&mut weapon_obj.gem);
            assert!(stored_gem == gem, error::not_found(EINVALID_GEM_UNEQUIP));
            object::transfer(owner, gem, signer::address_of(owner));
        }

        // Entry functions

        entry fun mint_hero(
            account: &signer,
            description: String,
            gender: String,
            name: String,
            race: String,
            uri: String,
        ) acquires OnChainConfig {
            create_hero(account, description, gender, name, race, uri);
        }

        entry fun set_hero_description(
            creator: &signer,
            collection: String,
            name: String,
            description: String,
        ) acquires Hero {
            let (hero_obj, hero) = get_hero(
                &signer::address_of(creator),
                &collection,
                &name,
            );
            let creator_addr = token::creator(hero_obj);
            assert!(creator_addr == signer::address_of(creator), error::permission_denied(ENOT_CREATOR));
            token::set_description(&hero.mutator_ref, description);
        }

        // View functions
        #[view]
        fun view_hero(creator: address, collection: String, name: String): Hero acquires Hero {
            let token_address = token::create_token_address(
                &creator,
                &collection,
                &name,
            );
            move_from<Hero>(token_address)
        }

        #[view]
        fun view_hero_by_object(hero_obj: Object<Hero>): Hero acquires Hero {
            let token_address = object::object_address(&hero_obj);
            move_from<Hero>(token_address)
        }

        #[view]
        fun view_object<T: key>(obj: Object<T>): String acquires Armor, Gem, Hero, Shield, Weapon {
            let token_address = object::object_address(&obj);
            if (exists<Armor>(token_address)) {
                string_utils::to_string(borrow_global<Armor>(token_address))
            } else if (exists<Gem>(token_address)) {
                string_utils::to_string(borrow_global<Gem>(token_address))
            } else if (exists<Hero>(token_address)) {
                string_utils::to_string(borrow_global<Hero>(token_address))
            } else if (exists<Shield>(token_address)) {
                string_utils::to_string(borrow_global<Shield>(token_address))
            } else if (exists<Weapon>(token_address)) {
                string_utils::to_string(borrow_global<Weapon>(token_address))
            } else {
                abort EINVALID_TYPE
            }
        }

        inline fun get_hero(creator: &address, collection: &String, name: &String): (Object<Hero>, &Hero) {
            let token_address = token::create_token_address(
                creator,
                collection,
                name,
            );
            (object::address_to_object<Hero>(token_address), borrow_global<Hero>(token_address))
        }

        #[test(account = @0x3)]
        fun test_hero_with_gem_weapon(account: &signer) acquires Hero, OnChainConfig, Weapon {
            init_module(account);

            let hero = create_hero(
                account,
                string::utf8(b"The best hero ever!"),
                string::utf8(b"Male"),
                string::utf8(b"Wukong"),
                string::utf8(b"Monkey God"),
                string::utf8(b""),
            );

            let weapon = create_weapon(
                account,
                32,
                string::utf8(b"A magical staff!"),
                string::utf8(b"Ruyi Jingu Bang"),
                string::utf8(b""),
                string::utf8(b"staff"),
                15,
            );

            let gem = create_gem(
                account,
                32,
                32,
                string::utf8(b"Beautiful specimen!"),
                string::utf8(b"earth"),
                string::utf8(b"jade"),
                string::utf8(b""),
            );

            let account_address = signer::address_of(account);
            assert!(object::is_owner(hero, account_address), 0);
            assert!(object::is_owner(weapon, account_address), 1);
            assert!(object::is_owner(gem, account_address), 2);

            hero_equip_weapon(account, hero, weapon);
            assert!(object::is_owner(hero, account_address), 3);
            assert!(object::is_owner(weapon, object::object_address(&hero)), 4);
            assert!(object::is_owner(gem, account_address), 5);

            weapon_equip_gem(account, weapon, gem);
            assert!(object::is_owner(hero, account_address), 6);
            assert!(object::is_owner(weapon, object::object_address(&hero)), 7);
            assert!(object::is_owner(gem, object::object_address(&weapon)), 8);

            hero_unequip_weapon(account, hero, weapon);
            assert!(object::is_owner(hero, account_address), 9);
            assert!(object::is_owner(weapon, account_address), 10);
            assert!(object::is_owner(gem, object::object_address(&weapon)), 11);

            weapon_unequip_gem(account, weapon, gem);
            assert!(object::is_owner(hero, account_address), 12);
            assert!(object::is_owner(weapon, account_address), 13);
            assert!(object::is_owner(gem, account_address), 14);
        }
    }
    """
  end

  defp local_compo() do
    """
    module 0x8675309::M {
       struct S has copy, drop { f: u64, g: u64 }
       fun id<T>(r: &T): &T {
           r
       }
       fun id_mut<T>(r: &mut T): &mut T {
           r
       }

       fun t0(cond: bool) {
           let s = S { f: 0, g: 0 };
           let f;
           if (cond) f = &s.f else f = &s.g;
           *f;
           s = S { f: 0, g: 0 };
           s;
       }

       fun t1(cond: bool, other: &mut S) {
           let s = S { f: 0, g: 0 };
           let f;
           if (cond) f = &mut s.f else f = &mut other.f;
           *f;
           s = S { f: 0, g: 0 };
           s;
       }

       fun t2(cond: bool, other: &mut S) {
           let s = S { f: 0, g: 0 };
           let f;
           if (cond) f = &mut s else f = other;
           *f;
           s = S { f: 0, g: 0 };
           s;
       }

       fun t3(cond: bool, other: &mut S) {
           let s = S { f: 0, g: 0 };
           let f;
           if (cond) f = id_mut(&mut s) else f = other;
           *f;
           s = S { f: 0, g: 0 };
           s;
       }

       fun t4(cond: bool) {
           let s = S { f: 0, g: 0 };
           let f = &s.f;
           if (cond) s = S { f: 0, g: 0 } else { *f; };
           s;
       }

    }

    """
  end
end
