WITH distinct_pages AS (
    SELECT DISTINCT cp_catalog_page_sk, cp_catalog_page_id
    FROM catalog_page
    WHERE cp_catalog_number > 10
),
sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(DISTINCT cust.c_customer_sk) AS distinct_customer_cnt
    FROM catalog_sales cs
    INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN customer cust
        ON cs.cs_bill_customer_sk = cust.c_customer_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN distinct_pages dp
        ON cs.cs_catalog_page_sk = dp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN web_site ws
        ON d_sold.d_date_sk = ws.web_open_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_category = 'Sports'
      AND cc.cc_state = 'CA'
      AND p.p_channel_email = 'N'
      AND ws.web_country = 'United States'
    GROUP BY cc.cc_call_center_id, i.i_category
)
SELECT
    cc_call_center_id,
    i_category,
    total_profit,
    order_cnt,
    avg_quantity,
    distinct_customer_cnt,
    ROUND(total_profit / NULLIF(order_cnt, 0), 2) AS avg_profit_per_order
FROM sales_agg
WHERE total_profit > 10000
ORDER BY total_profit DESC
LIMIT 100
