WITH monthly_cc AS (
    SELECT
        cc.cc_call_center_id AS cc_id,
        cc.cc_name AS cc_name,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(CASE WHEN cs.cs_ext_list_price = 0 THEN NULL ELSE cs.cs_ext_discount_amt / cs.cs_ext_list_price END) AS avg_discount_rate,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold
    FROM
        catalog_sales cs
    JOIN
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN
        call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN
        ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        d.d_year = 2001
        AND cc.cc_market_manager IN ('Julius Tran', 'Gary Colburn')
        AND i.i_category = 'Books'
        AND sm.sm_type = 'AIR'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        d.d_year,
        d.d_month_seq
    HAVING
        SUM(cs.cs_net_profit) > 10000
)
SELECT
    cc_id,
    cc_name,
    d_year,
    d_month_seq,
    total_profit,
    total_sales,
    avg_discount_rate,
    distinct_items_sold,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_profit DESC) AS profit_rank
FROM
    monthly_cc
ORDER BY
    d_year,
    d_month_seq,
    profit_rank
LIMIT 100
