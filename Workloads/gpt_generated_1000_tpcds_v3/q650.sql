WITH base AS (
    SELECT
        d.d_date,
        d.d_date_sk,
        d.d_day_name,
        d.d_dow,
        d.d_following_holiday,
        t.t_shift,
        t.t_am_pm,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_ship_customer_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        s.s_store_id,
        s.s_store_name,
        cc.cc_name,
        w.w_warehouse_name,
        ws.web_name
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_day_name = 'Wednesday'
      AND d.d_dow = 3
      AND d.d_following_holiday = 'N'
      AND t.t_shift = 'first'
      AND t.t_am_pm = 'PM'
      AND cs.cs_ship_customer_sk IN (4098294, 3691720)
      AND cs.cs_sales_price > 50
)
SELECT
    b.d_date,
    b.s_store_id,
    b.s_store_name,
    b.cc_name,
    b.w_warehouse_name,
    b.web_name,
    COUNT(DISTINCT b.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT b.ss_ticket_number) AS store_ticket_cnt,
    SUM(b.cs_ext_sales_price) AS total_catalog_sales,
    SUM(b.ss_ext_sales_price) AS total_store_sales,
    AVG(b.cs_ext_discount_amt) AS avg_catalog_discount,
    AVG(b.ss_ext_discount_amt) AS avg_store_discount,
    MAX(b.cs_net_profit) AS max_catalog_profit,
    MIN(b.ss_net_profit) AS min_store_profit,
    (SELECT MAX(cs2.cs_ext_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_sold_date_sk = b.d_date_sk) AS max_date_catalog_ext_sales_price
FROM base b
GROUP BY
    b.d_date,
    b.d_date_sk,
    b.s_store_id,
    b.s_store_name,
    b.cc_name,
    b.w_warehouse_name,
    b.web_name
HAVING SUM(b.cs_ext_sales_price) > 10000
ORDER BY total_catalog_sales DESC
LIMIT 100
