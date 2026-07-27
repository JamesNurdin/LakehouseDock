WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d1.d_year AS year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d1 ON ws.ws_sold_date_sk = d1.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d1.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d1.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d1.d_current_year = 'Y'
      AND d1.d_same_day_ly BETWEEN 2414650 AND 2414680
      AND p.p_channel_tv = 'N'
      AND c.c_preferred_cust_flag = 'Y'
      AND ib.ib_upper_bound > 50000
    GROUP BY s.s_store_id, d1.d_year
)
SELECT
    store_id,
    year,
    total_sales,
    total_profit,
    sales_cnt,
    CASE
        WHEN total_profit / NULLIF(total_sales, 0) > 0.20 THEN 'Profitable'
        ELSE 'LowMargin'
    END AS profit_category,
    (SELECT AVG(total_sales) FROM sales_agg) AS avg_total_sales_all_stores,
    CASE
        WHEN total_sales > (SELECT AVG(total_sales) FROM sales_agg) THEN 'AboveAvg'
        ELSE 'BelowAvg'
    END AS sales_relative_category
FROM sales_agg
WHERE total_sales > (SELECT AVG(total_sales) FROM sales_agg)
ORDER BY total_profit DESC
LIMIT 100
