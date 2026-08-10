select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 851 and 851+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'grey') and 
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'linen' or i_color = 'lace') and
        (i_units = 'Oz' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'rosy') and
        (i_units = 'Gram' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'metallic') and
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'violet' or i_color = 'olive') and 
        (i_units = 'Box' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'medium' or i_color = 'antique') and
        (i_units = 'Pound' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'orchid') and
        (i_units = 'Carton' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'drab') and
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
