/*
  Goal: Identify which promotions drive the highest net profit at each warehouse, compare each promotion's profit to the warehouse's average profit, and rank promotions within warehouses, while also showing warehouses with sales but no associated promotion.
*/
WITH sales_by_wh_promo AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_coupon_amt) AS avg_coupon_amt,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_warehouse_sk, cs.cs_promo_sk
),
warehouse_stats AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_county,
        w.w_state,
        AVG(s.total_net_profit) AS avg_warehouse_net_profit
    FROM sales_by_wh_promo s
    JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_county, w.w_state
),
promo_details AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_purpose,
        p.p_start_date_sk,
        p.p_end_date_sk
    FROM promotion p
    WHERE p.p_purpose = 'Unknown'
)
SELECT
    w.w_warehouse_name,
    w.w_county,
    COALESCE(pd.p_promo_name, 'No Promotion') AS promo_name,
    pd.p_purpose,
    s.total_sales,
    s.total_net_profit,
    s.avg_coupon_amt,
    s.sales_cnt,
    ws.avg_warehouse_net_profit,
    ROUND((s.total_net_profit - ws.avg_warehouse_net_profit) / ws.avg_warehouse_net_profit * 100, 2) AS profit_vs_warehouse_pct,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY s.total_net_profit DESC) AS profit_rank_within_warehouse
FROM sales_by_wh_promo s
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promo_details pd ON s.cs_promo_sk = pd.p_promo_sk
JOIN warehouse_stats ws ON w.w_warehouse_sk = ws.w_warehouse_sk
WHERE s.total_sales > 10000
ORDER BY w.w_warehouse_name, profit_rank_within_warehouse
