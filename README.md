# License Detector (Experimental)

## Current Implementation:

- Normalization of text:
    - Copyright Notice
    - License Header
    - Bullets
    - Extraneous White Spaces
- Tokenization and generation of hashed q-grams. The Crc32 algorithm is used for hashing the q-grams.
- Check whether a possible match or not and then calculate the final confidence.

*NOTE:* The current implementation is just for experimental purpose. Its just a depiction of how the application will work.


**After testing for various threshold values, I have found that a threshold of 85% works well.**

**Explanation:** In some cases, the Dice Coefficient was near above 85% however the final confidence was about 95%, hence the 85% threshold value fits for almost all licenses.

[LicenseClassifier](https://github.com/google/licenseclassifier/blob/bb04aff29e72e636ba260ec61150c6e15f111d7e/stringclassifier/classifier.go#L70) which uses almost the same approach to detect licenses has a [threshold value](https://github.com/google/licenseclassifier/blob/bb04aff29e72e636ba260ec61150c6e15f111d7e/stringclassifier/classifier.go#L70) of 80% 


### Output for a normal case:
```
Normalizing texts...
Normalized --> Elapsed: 21 ms

Tokenizing...
Created tokens --> Elapsed: 0 ms

Creating q-grams...
Created q-grams --> Elapsed: 15 ms

Calculating possibility...
It is a possible match: 94.32098765432099% --> Elapsed: 33 ms

Calculating final confidence...
Calculated confidence --> Elapsed: 16 ms

Confidence: 98.44632768361582%

Its a match!!
```

### Output when the order of the text is changed:
```
Normalizing texts...
Normalized --> Elapsed: 20 ms

Tokenizing...
Created tokens --> Elapsed: 0 ms

Creating q-grams...
Created q-grams --> Elapsed: 12 ms

Calculating possibility...
It is a possible match: 88.39506172839506% --> Elapsed: 23 ms

Calculating final confidence...
Calculated confidence --> Elapsed: 30 ms

Confidence: 73.94067796610169%

Not a match :(
``` 
**The above example clearly demonstrates why the Dice Coefficient is not a determining factor because it doesn't take into account the order of the text. The unordered text passes the possibility check, however, its not a match since the order of the text is different. Calculating the confidence using the Levenshtein distance solves the problem.**