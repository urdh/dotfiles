function anonymize_exif --description 'Remove personal info from EXIF data'
	exiftool -creator= -creatorworktelephone= -creatorcountry= \
			 -creatorworkurl= -creatoraddress= -creatorpostalcode= \
			 -creatorcity= -creatorworkemail= -credit= -rights= \
			 -usercomment= -copyright= -artist= -subject= -by-line= \
			 -keywords= -copyrightnotice= -overwrite_original $argv
end
