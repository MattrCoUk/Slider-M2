# Slider M2

Slider Extension for Magento 2.x

## Installation (this fork)

`cd [__magento_project_dir__]`

`mkdir -p app/code/SY/Slider; cd  app/code/SY/Slider`

Options

1. Using **HTTPS**  
`git clone https://github.com/MattrCoUk/Slider-M2.git`

2. or simply **[download](https://github.com/MattrCoUk/Slider-M2/archive/master.zip)** and unzip the repo in `[__magento_project_dir__]/app/code/SY/Slider ` 

3. or **SSH** if planning to push to origin  
`git clone git@github.com:MattrCoUk/Slider-M2.git .`

then   

`cd [__magento_project_dir__]`

`bin/magento module:enable SY_Slider`

`bin/magento setup:upgrade`

`bin/magento cache:flush`

**Coffe break mode**

`cd [__magento_project_dir__]; bin/magento module:enable SY_Slider; bin/magento setup:upgrade; bin/magento cache:flush`



## Uninstallation

in `magento_project_dir`

`bin/magento module:disable SY_Slider`

`rm -rf app/code/SY/Slider`


###Clear database
Drop `schema.sy_slider` table.
delete from `schema.setup_module where module ='SY_Slider';`


`bin/magento setup:upgrade`

`bin/magento cache:flush`


## More info


[GUIDE](https://github.com/SlavaYurthev/Slider-M2/wiki)
