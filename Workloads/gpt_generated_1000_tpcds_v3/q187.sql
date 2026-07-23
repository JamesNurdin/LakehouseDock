WITH daily_sales AS (
    SELECT
        d_sold.d_year,
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        SUM(cs.cs_net_paid) AS daily_sales,
        SUM(cs.cs_net_profit) AS daily_profit,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS daily_returns,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS daily_return_qty,
        COUNT(DISTINCT cs.cs_order_number) AS daily_orders
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND cc.cc_state = 'CA'
        AND cp.cp_type = 'promotional'
        AND i.i_brand = 'Brand#12'
        AND hd.hd_buy_potential = '>10000'
        AND wp.wp_max_ad_count >= 2
    GROUP BY
        d_sold.d_year,
        i.i_item_sk,
        i.i_brand,
        i.i_category
)
SELECT
    d_year,
    i_brand,
    i_category,
    SUM(daily_sales) AS total_sales,
    SUM(daily_profit) AS total_profit,
    SUM(daily_returns) AS total_returns,
    SUM(daily_return_qty) AS total_return_qty,
    AVG(daily_sales) AS avg_daily_sales,
    COUNT(*) AS days_with_sales
FROM daily_sales
GROUP BY
    d_year,
    i_brand,
    i_category
HAVING
    SUM(daily_sales) > 100000
ORDER BY total_sales DESC
LIMIT 100
