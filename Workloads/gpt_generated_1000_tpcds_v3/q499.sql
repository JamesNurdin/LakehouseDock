WITH sales_by_item AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_state AS state,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_item_sk AS item_sk,
        i.i_brand_id,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(CASE WHEN sm.sm_carrier = 'FEDEX' THEN ss.ss_ext_sales_price ELSE 0 END) AS fedex_sales,
        SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS catalog_profit,
        COUNT(*) AS transactions
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND i.i_brand_id = 10008011
      AND s.s_state = 'CA'
      AND sm.sm_carrier = 'FEDEX'
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_id, s.s_state, d.d_year, d.d_month_seq, i.i_item_sk, i.i_brand_id, i.i_category
)
SELECT
    store_id,
    state,
    year,
    month_seq,
    AVG(total_sales) AS avg_monthly_sales,
    AVG(total_profit) AS avg_monthly_profit,
    SUM(CASE WHEN total_profit > 0 THEN 1 ELSE 0 END) AS profit_months,
    CASE WHEN AVG(total_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = sb.item_sk) AS avg_item_promo_cost
FROM sales_by_item sb
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
    WHERE wr2.wr_item_sk = sb.item_sk
      AND r2.r_reason_desc = 'Damaged'
)
GROUP BY store_id, state, year, month_seq, sb.item_sk
HAVING AVG(total_sales) > 1000
ORDER BY avg_monthly_sales DESC
LIMIT 100
