---
title: 'My Advent Of Rust, Day 4'
date: 2020-12-13 01:00:00
featured_image: '/images/advent-rust/adventofrust.png'
excerpt: Notes on day 4 of advent of code made in Rust.
---

![](/images/adventofrust/adventofrust.png)

# I've always considered programming challenges a fun way of experimenting new languages.

For this edition of advent of code (2020), i decided i would give [Rust](https://www.rust-lang.org/) a try.

Rust really makes your head spin a bit with supposedly trivial problems (and this is a good thing!).

This is mainly because programming in **Rust requires you to think differently**.

Replicating patterns that are common in other languages is tricky and sometimes quite hard or even impossible.

Day 4 was a good example, so let's examine the [challenge](https://adventofcode.com/2020/day/4), which i will try to resume:

 - You have a big string input, containing representations of passports.
 - On double newline, you have a passport.
 - Each **valid** passport consists of the following fields: "byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid".
 - Find all valid passports.

We'll, first lets transform the input into something useful. This is the "similar" part of the Rust code to the rest of the other languages.

I'm sure there would be many ways of doing this but i have chosen:


```rust
 let result = fs::read_to_string("input_day_four.txt").unwrap();
 let passports = result.split("\n\n");
```
  

so i have copied the input into a file (as a noobie, i prefered not to perform an http request :p ), read it to a String (unwrap to obtain the string is unsafe an discouraged, i know. but since i am controling the input, it is sufficient) and then split it to obtain each passport.

Why not doing it in one line like :
```rust
   let passports: Vec<&str> = fs::read_to_string("input_day_four.txt")
        .unwrap()
        .split("\n\n")
```
Well... because using **unwrap creates a temporary which is freed while still in use**. And in Rust this means that i need to create a new variable if i want to continue.

So how do i verify which passports are valid?

Using a language like [Go](https://golang.org/), i would probably loop the separated strings, find the index of `:` and then try to delete an entry using the index. Then i would assert if the len of the map was equal to zero. If yes, then it is a valid passport. That could be represented as such:

```go
validPassportCounter := 0
for _, passport := range passports {
	control := map[string]struct{}{
		"byr": struct{}{},
		"iyr": struct{}{},
		"eyr": struct{}{},
		"hgt": struct{}{},
		"hcl": struct{}{},
		"ecl": struct{}{},
		"pid": struct{}{},
	}

	for i, ch := range passport {
		if ch == ':' {
		  	delete(control, passport[i-3:i])
		}
	}

	if len(control) == 0 {
		validPassportCounter++
	}
}
```
another way would be to split whitespace an find the strings starting with the desired fields like so:

```go
validPassportCounter := 0
for _, passport := range passports {
        control := 0
	fields := strings.Fields(passport)
	for _, field := range fields {
		if strings.HasPrefix(field, "byr") || strings.HasPrefix(field, "iyr") ||
			 strings.HasPrefix(field, "eyr") || strings.HasPrefix(field, "hgt") || 				strings.HasPrefix(field, "hcl") ||
				strings.HasPrefix(field, "ecl") || strings.HasPrefix(field, "pid") {
				control++
		}
	}

	if control == 7 {
		validPassportCounter++
	}
}
```
Using these patterns proved to be quite challenging in Rust. I kept fighting the compiler, and the compiler kept winning.

> So i went back to sketching... what was i really trying to do?

I have a vector of references to strings to which i wanted to filter the ones containing the right values and then count the collected values.


Looking at [Iter]( https://doc.rust-lang.org/std/iter/struct.Filter.html#method.count ) i found that using an iterator i could [filter](https://doc.rust-lang.org/std/iter/struct.Filter.html) elements with a predicate and then [count](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.count) the filtered entries.

Horaay!

So i am on to something. I wrote:
```rust
let valid_passports = passports
        .filter()
        .count();
```
So now i only need a predicate that filters the strings i need!

the predicate could be similar to the second golang approach:
```rust
fn check_validity_part_1(passport: &str) -> bool {
	let fields = vec!["byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid"];
	fields.iter().all(|field| {
		passport
		.split_ascii_whitespace()
		.any(|passport_field| passport_field.starts_with(field))
	})
}
```
so again i ask for my new BFF [Iterator](https://doc.rust-lang.org/std/iter/trait.Iterator.html), which holds an [all](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.all) method that tests if every element of passport verifies a predicate.

The predicate i want is for each **field of a passport**, determine if the passport_field starts with any of the values of **fields**.

For that, i've use a  [split_ascii_whitespace](https://doc.rust-lang.org/std/primitive.str.html#method.split_ascii_whitespace) to obtain the passport fields, and [any](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.any) to verify passport correctness.

Voila!

Now gluing it all together...  **it compiles!!!!! YES!! We are the champions!!!!** 

i just had to make every passport pass the predicate **check_validity_part_1** that i wrote previously:
```rust
let result = fs::read_to_string("input_day_four.txt").unwrap();

let passports = result.split("\n\n");

let valid_passports = passports
        .filter(|passport| check_validity_part_1(passport))
        .count();

println!("{}", valid_passports);
```
and this piece gives the correct input to the first challenge of the 4 day :)

---

> Some lessons to myself: don't fight the compiler. If your approach/pattern is not working, it is probably because you probably cannot use this same pattern using Rust. Stop, re-evaluate, read the documentation, and surely you'll find a way of solving the problem.

### If this was the optimal approach... well, that should be re-evaluated, once i have a better knowledge of Rust :)

This blog was originally posted on [Medium](https://seomisw.medium.com/my-advent-of-rust-day-4-bc3a9e76a85b){:target="_blank"}--be sure to follow and clap!


