WITH item_brands AS (
    SELECT i_brand AS attribute,
           'item' AS source
    FROM item
    WHERE i_rec_start_date <= DATE '2000-12-31'
      AND i_rec_end_date >= DATE '2000-01-01'
),
web_states AS (
    SELECT web_state AS attribute,
           'web_site' AS source
    FROM web_site
    WHERE web_rec_end_date > DATE '2005-01-01'
)
SELECT attribute, source FROM item_brands
UNION
SELECT attribute, source FROM web_states
ORDER BY attribute
