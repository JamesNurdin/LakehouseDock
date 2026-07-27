WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_cdemo_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        i.i_item_id,
        cd.cd_gender,
        d.d_year,
        d.d_month_seq
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_item_desc, '(?i)steel|plastic')
      AND i.i_current_price > 20
),
joined_data AS (
    SELECT
        fr.*, 
        cp.cp_catalog_page_number,
        cp.cp_description
    FROM filtered_returns fr
    JOIN catalog_page cp
      ON cp.cp_start_date_sk = fr.sr_returned_date_sk
         OR cp.cp_end_date_sk = fr.sr_returned_date_sk
    WHERE cp.cp_description LIKE '%holiday%'
      AND regexp_extract(cp.cp_description, '([A-Za-z]+) Holiday', 1) = 'Winter'
)
SELECT
    jd.cp_catalog_page_number,
    jd.d_year,
    jd.i_brand,
    jd.cd_gender,
    COUNT(*) AS returns_cnt,
    SUM(jd.sr_return_amt) AS total_return_amount,
    SUM(jd.sr_net_loss) AS total_net_loss,
    CONCAT(jd.i_brand, ':', SUBSTRING(jd.i_item_id, 1, 4)) AS brand_item_prefix,
    MAX(jd.i_product_name) FILTER (WHERE regexp_like(jd.i_product_name, '^.*Pro.*$')) AS sample_pro_product
FROM joined_data jd
GROUP BY
    jd.cp_catalog_page_number,
    jd.d_year,
    jd.i_brand,
    jd.cd_gender,
    CONCAT(jd.i_brand, ':', SUBSTRING(jd.i_item_id, 1, 4))
ORDER BY total_return_amount DESC
LIMIT 100
