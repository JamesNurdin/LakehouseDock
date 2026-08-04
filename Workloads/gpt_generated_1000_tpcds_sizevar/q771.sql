WITH
store_side AS (
    SELECT
        ss.ss_sold_time_sk AS time_sk,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        s.s_store_name AS s_store_name,
        i.i_item_sk,
        i.i_brand,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv TABLESAMPLE BERNOULLI (10) ON inv.inv_item_sk = i.i_item_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND i.i_brand = 'BrandX'
      AND s.s_state = 'CA'
      AND ca.ca_country = 'United States'
      AND cd.cd_gender = 'M'
),
catalog_side AS (
    SELECT
        cr.cr_returned_time_sk AS time_sk,
        cr.cr_return_quantity AS cr_return_quantity,
        cr.cr_return_amount AS cr_return_amount,
        r.r_reason_desc AS r_reason_desc,
        cp.cp_department,
        ca.ca_state,
        cd.cd_education_status,
        hd.hd_vehicle_count,
        i.i_category
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_id = 'AAAAAAAALAAAAAAA'
      AND cp.cp_department = 'Electronics'
      AND td.t_am_pm = 'PM'
      AND cd.cd_education_status = 'College'
      AND ca.ca_state = 'NY'
),
full_joined AS (
    SELECT
        COALESCE(ss.time_sk, cr.time_sk) AS time_sk,
        ss.ss_quantity,
        cr.cr_return_quantity,
        ss.ss_net_paid,
        cr.cr_return_amount,
        ss.s_store_name,
        cr.r_reason_desc
    FROM store_side ss
    FULL OUTER JOIN catalog_side cr ON ss.time_sk = cr.time_sk
),
web_side AS (
    SELECT
        ws.ws_sold_time_sk AS time_sk,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_ext_discount_amt,
        i.i_category,
        wsite.web_name,
        ws.ws_ext_sales_price
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE td.t_shift = 'first'
      AND wsite.web_state = 'TX'
      AND i.i_color = 'Red'
      AND ws.ws_ext_discount_amt > 1000
      AND ws.ws_quantity >= 2
)
SELECT
    time_sk,
    SUM(COALESCE(ss_quantity, 0) + COALESCE(cr_return_quantity, 0)) AS total_quantity,
    SUM(COALESCE(ss_net_paid, 0) + COALESCE(cr_return_amount, 0)) AS total_amount,
    COUNT(*) AS row_cnt,
    MAX(s_store_name) AS store_name,
    MIN(r_reason_desc) AS reason_desc
FROM full_joined
GROUP BY time_sk
HAVING SUM(COALESCE(ss_net_paid, 0) + COALESCE(cr_return_amount, 0)) > (
    SELECT MAX(ss_net_paid) FROM store_sales WHERE ss_sold_date_sk = 2451015
)
UNION DISTINCT
SELECT
    time_sk,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_net_paid) AS total_amount,
    COUNT(*) AS row_cnt,
    MAX(i_category) AS store_name,
    MIN(web_name) AS reason_desc
FROM web_side
GROUP BY time_sk
ORDER BY total_amount DESC
LIMIT 100
