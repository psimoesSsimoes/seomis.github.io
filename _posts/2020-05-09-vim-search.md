---
title: 'Easy search in VIM'
date: 2020-05-09 00:00:00
featured_image: '/images/vim_search/vimgrep.gif'
excerpt: VIM + Functions + ACK == WIN!.
---

![](/images/vim_search/vimgrep.gif)

## Easy search in VIM

 Every developer needs a fast way to search for a current word in multiple files.

As a [vim](https://github.com/vim){:target="_blank"} user the way i used to do it would be in the form :
```
:Ack! < word > < directory_where_i_want_to_search >
```

Surely there must be a better way!

That way was presented to me by my vim partner in crime, Mr João Seabra.
He wrote a small [vim function](https://learnvimscriptthehardway.stevelosh.com/chapters/23.html){:target="_blank"} which i find particularly useful for my daily workflow:

```vim
function! s:GrepOperator()
    let wordUnderCursor = expand("<cword>")
    silent execute "Ack! " . shellescape(wordUnderCursor) . " " . g:var_default
    copen
    redraw!
endfunction
```

Let's understand how it works:

```vim
let wordUnderCursor = expand("<cword>")
```

we start by declaring a variable which will hold the word under cursor

```vim
silent execute "Ack! " . shellescape(wordUnderCursor) . " " . g:var_default
```

we execute the shell command silently (in my case i like to use a code searching tool similar to ack called the_silver_searcher) providing the wordUnderCursor and the directory where we want where we want to search (which is stored in a global variable var_default)

```vim
copen
redraw!
```

we open the quickfix window and we force a screen refresh

Note that you could any grep-like tool you prefer instead of **Ack**.

I also recomend reading **help cword** to get more options. For my vimrc, I needed **cWORD** to grab the whitespace delimited text under the cursor.

## How do you fill the global variable with the directory to search in?

In my case i find it useful to set it to the **current working directory**. That can be achieved by setting in your vimrc the following line:

```vim
let g:var_default = getcwd()
```

## How do we call the function quickly?

for that we need a mapping!  That is achieved with the following lines:

```vim
vnoremap <leader>z :<c-u>call <SID>GrepOperator()<cr>
noremap <leader>z :<c-u>call <SID>GrepOperator()<cr>
```

with these lines i can call the vim function in normal and visual mode. In my case, you can see that i map it for < leader > z.

To wrap it up, a fast way to navigate the result documents can be done with the following mappings:

```vim
nnoremap <leader>j :cnext<CR>
nnoremap <leader>k :cprevious<CR>
```

using **< leader >j** , we navigate to the next result.

using **< leader >k** , we navigate to the previous result.


That's it! Now we have a quick and practical way of searching words in vim!

### Do you have a different/better way of achieving the same result?
### I would love to hear about it :)


This blog was originally posted on [Medium](https://link.medium.com/QyA2B23on6){:target="_blank"}--be sure to follow and clap!
