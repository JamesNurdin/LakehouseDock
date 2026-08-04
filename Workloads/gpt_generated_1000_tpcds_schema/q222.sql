WITH filtered AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_addr_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_ship_cost,
        d.d_date,
        d.d_year,
        t.t_hour,
        i.i_class_id,
        i.i_category,
        i.i_manufact,
        ca.ca_state,
        cd.cd_gender,
        p.p_promo_name,
        p.p_channel_radio,
        wr.wr_return_amt AS web_return_amt,
        wp.wp_url
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'TX'
      AND i.i_class_id = 6
      AND p.p_channel_radio = 'N'
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
),
cust_excl AS (
    SELECT sr.sr_customer_sk
    FROM store_returns sr
    WHERE sr.sr_return_amt > 0
    EXCEPT
    SELECT wr.wr_refunded_customer_sk
    FROM web_returns wr
    WHERE wr.wr_return_amt > 0
)
SELECT
    f.d_year,
    f.i_category,
    f.ca_state,
    f.p_promo_name,
    COUNT(DISTINCT f.sr_return_quantity) AS distinct_return_qty,
    SUM(f.sr_return_amt) AS total_store_return,
    SUM(f.web_return_amt) AS total_web_return,
    AVG(f.sr_return_tax) AS avg_store_tax,
    MIN(f.sr_return_ship_cost) AS min_ship_cost,
    MAX(f.sr_return_ship_cost) AS max_ship_cost,
    SUM(SUM(f.sr_return_amt)) OVER (PARTITION BY f.ca_state ORDER BY f.d_date ROWS UNBOUNDED PRECEDING) AS running_store_return_by_state,
    COUNT(DISTINCT CASE WHEN f.sr_customer_sk IN (SELECT sr_customer_sk FROM cust_excl) THEN f.sr_customer_sk END) AS exclusive_store_customers
FROM filtered f
GROUP BY
    f.d_year,
    f.i_category,
    f.ca_state,
    f.p_promo_name,
    f.d_date
ORDER BY total_store_return DESC
LIMIT 100
