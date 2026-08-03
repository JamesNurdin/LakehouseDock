WITH
    sold_items AS (
        SELECT DISTINCT ws.ws_item_sk
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE regexp_like(i.i_item_desc, '(?i)soft')
    ),
    returned_items AS (
        SELECT DISTINCT sr.sr_item_sk
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE regexp_like(i.i_item_desc, '(?i)soft')
    ),
    sold_not_returned AS (
        SELECT ws_item_sk FROM sold_items
        EXCEPT
        SELECT sr_item_sk FROM returned_items
    ),
    sales_agg AS (
        SELECT
            ca.ca_county,
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
            CASE
                WHEN SUM(ws.ws_net_paid_inc_ship_tax) > 5000 THEN 'High'
                WHEN SUM(ws.ws_net_paid_inc_ship_tax) > 2000 THEN 'Medium'
                ELSE 'Low'
            END AS sales_category,
            regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word,
            ROW_NUMBER() OVER (PARTITION BY ca.ca_county ORDER BY SUM(ws.ws_net_paid_inc_ship_tax) DESC) AS rn
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE i.i_item_sk IN (SELECT ws_item_sk FROM sold_not_returned)
          AND regexp_like(i.i_item_desc, '(?i)soft')
          AND ca.ca_county LIKE '%County'
        GROUP BY ca.ca_county, i.i_item_sk, i.i_item_id, i.i_product_name, i.i_item_desc
    ),
    county_dim AS (
        SELECT DISTINCT ca_county
        FROM customer_address
        WHERE ca_county LIKE '%County'
        LIMIT 10
    ),
    rank_numbers AS (
        SELECT rank_num
        FROM (VALUES (1), (2), (3), (4), (5)) AS t(rank_num)
    ),
    final_set AS (
        SELECT
            sd.ca_county,
            sd.i_item_id,
            sd.i_product_name,
            sd.total_sales,
            sd.sales_category,
            sd.first_word,
            rn.rank_num,
            CONCAT(sd.ca_county, ' (Rank ', CAST(rn.rank_num AS varchar), ')') AS county_rank_label
        FROM county_dim cd
        CROSS JOIN rank_numbers rn
        JOIN sales_agg sd
            ON sd.ca_county = cd.ca_county
            AND sd.rn = rn.rank_num
    )
SELECT
    ca_county,
    i_item_id,
    i_product_name,
    total_sales,
    sales_category,
    first_word,
    rank_num,
    county_rank_label
FROM final_set
WHERE rank_num <= 5
ORDER BY ca_county, total_sales DESC
LIMIT 100
