/* goal: Analyse combined store and web returns by product category, customer gender and year, using deep joins, a sampled inventory, a scalar subquery price filter, CUBE grouping, and a global row number */
WITH inv_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT
    i.i_category,
    cd.cd_gender,
    d_ret.d_year,
    SUM(sr.sr_return_amt) AS store_return_total,
    SUM(wr.wr_return_amt) AS web_return_total,
    SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt) AS total_return_amt,
    ROW_NUMBER() OVER (ORDER BY (SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt)) DESC) AS rn
FROM
    store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d_web
        ON wr.wr_returned_date_sk = d_web.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_create
        ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN inv_sample inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_ret.d_date_sk
WHERE
    i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
    AND cd.cd_education_status = '4 yr Degree'
GROUP BY CUBE (i.i_category, cd.cd_gender, d_ret.d_year)
ORDER BY total_return_amt DESC
LIMIT 100
