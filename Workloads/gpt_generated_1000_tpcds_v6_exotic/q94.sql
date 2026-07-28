WITH cs_agg AS (
    SELECT cs_item_sk,
           SUM(cs_net_paid) AS total_net_paid,
           COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 0
    GROUP BY cs_item_sk
),
cs_detail AS (
    SELECT cs_item_sk,
           MIN(cs_call_center_sk) AS call_center_sk,
           MIN(cs_catalog_page_sk) AS catalog_page_sk,
           MIN(cs_sold_date_sk) AS sold_date_sk,
           MIN(cs_sold_time_sk) AS sold_time_sk,
           MIN(cs_bill_addr_sk) AS bill_addr_sk,
           MIN(cs_bill_cdemo_sk) AS bill_cdemo_sk,
           MIN(cs_bill_hdemo_sk) AS bill_hdemo_sk,
           MIN(cs_order_number) AS order_number
    FROM catalog_sales
    GROUP BY cs_item_sk
)
SELECT
    i.i_item_id,
    i.i_brand,
    i.i_class,
    p.p_promo_name,
    cc.cc_name,
    cp.cp_department,
    d_sold.d_year,
    t.t_shift,
    SUM(ca_agg.total_net_paid)               AS sum_total_net_paid,
    COUNT(DISTINCT ca_agg.sales_cnt)          AS distinct_sales_cnt,
    AVG(p.p_cost)                             AS avg_promo_cost,
    MAX(cr.cr_net_loss)                       AS max_return_loss,
    COUNT(DISTINCT ws.ws_order_number)        AS web_order_cnt,
    s.s_store_name
FROM cs_agg ca_agg
JOIN cs_detail cd ON ca_agg.cs_item_sk = cd.cs_item_sk
JOIN item i ON ca_agg.cs_item_sk = i.i_item_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN call_center cc ON cd.call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cd.catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold ON cd.sold_date_sk = d_sold.d_date_sk
JOIN time_dim t ON cd.sold_time_sk = t.t_time_sk
JOIN customer_address ca ON cd.bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cdemo ON cd.bill_cdemo_sk = cdemo.cd_demo_sk
JOIN household_demographics hd ON cd.bill_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cd.order_number
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_class = 'sports-apparel'
  AND t.t_shift = 'first'
  AND cc.cc_state = 'CA'
  AND s.s_state = 'CA'
GROUP BY
    i.i_item_id,
    i.i_brand,
    i.i_class,
    p.p_promo_name,
    cc.cc_name,
    cp.cp_department,
    d_sold.d_year,
    t.t_shift,
    s.s_store_name
HAVING SUM(ca_agg.total_net_paid) > 100000
ORDER BY sum_total_net_paid DESC
LIMIT 100
