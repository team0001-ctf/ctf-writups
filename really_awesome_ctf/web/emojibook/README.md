
# RACTF: emojibook 1 writeup. SSTI in custom template implementation.


# Table of contents
- Setup
- the bug
- Exploiting emojibook 1


## description



## setup

The webapp has 4 main functions: login, register, new note, home. It is important to create an account **and** login otherwise the app doesnt work.

Under the "new note" tab you can create a a note, that can later be viewed on the home tab. In your notes you can add emojis with :emoji\_name:



## the bug

After looking through the sources that they provided in emojibook1, I came across this function in `notes/views.py`:
```py
 1    # responsible for displaying a note to the user
 2    def view_note(request: HttpRequest, pk: int) -> HttpResponse:
 3        note = get_object_or_404(Note, pk=pk)
 4        text = note.body
 5        for include in re.findall("({{.*?}})", text):
 6            print(include)
 7            ## NOTE: as we can control what is in the template things we might have something interesting here
 8            file_name = os.path.join("emoji", re.sub("[{}]", "", include))
 9            with open(file_name, "rb") as file:
 10               text = text.replace(include, f"<img src=\"data:image/png;base64,{base64.b64encode(file.read()).decode('latin1')}\" width=\"25\" height=\"25\" />")
 11
 12       return render(request, "note.html", {"note": note, "text": text})
```

On line 5 you can see that it is looking for `{{ expression }}` in the note. This immediately looks like some sort of custom templating for creating the html. We can also see later on that it tries to find a file name inside the template, reads and encodes it with base64 and returns it as an image.

This sounds like a recipie for an arbitrary read. Obviously its not as simple as just creating a note with `{{/flag.txt}}` because `{{` simbols get filtered somewhere else in code.

In `notes/forms.py` we find the function responsible for saving notes and filtering out dangerous characters:
```py
 1    def save(self, commit=True):
 2        instance = super(NoteCreateForm, self).save(commit=False)
 3        instance.author = self.user
 4        instance.body = instance.body.replace("{{", "").replace("}}", "").replace("..", "")
 5 
 6        with open("emoji.json") as emoji_file:
 7            emojis = json.load(emoji_file)
 8 
 9            for emoji in re.findall("(:[a-z_]*?:)", instance.body):
 10               instance.body = instance.body.replace(emoji, "{{" + emojis[emoji.replace(":", "")] + ".png}}")
 11
 12       if commit:
 13           instance.save()
 14           self._save_m2m()
 15
 16       return instance
 17
```

The filtering takes place on line 4. It first removes all instances of `{{` then `}}` and finally `..`. This is a problem because if someone were to add `{..{ filename }..}` it would remove nothing on the first two replace operations and remove the `..` last, creating a valid template. (`{{ filename }}`)




## exploiting emojibook 1

Using what we have found so far we can create a note (payload) as follows:
```
{..{/flag.txt}..}
```

This returns a broken image. Looking into the page source you can see that the image is being supplied as a base64 encoded string, decoding that lands us the flag.
```
ractf{dj4ng0_lfi}
```

NOTE: referencing an invalid file returns 500 and not 404.
