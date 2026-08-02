/* Goal: Calculate net sales per household demographic by combining catalog sales and store returns, rank them, filter for high net sales, and show total promotion count. */
WITH sales_agg AS (
    SELECT
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        cs.cs_promo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_paid_inc_ship) AS avg_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_quantity >= 2
      AND cs.cs_wholesale_cost >= 20
      AND p.p_cost > 100
    GROUP BY cs.cs_bill_hdemo_sk, cs.cs_promo_sk
),
returns_agg AS (
    SELECT
        sr.sr_hdemo_sk AS hd_demo_sk,
        sr.sr_store_sk AS store_sk,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 10
      AND s.s_state = 'CA'
      AND hd.hd_vehicle_count >= 1
    GROUP BY sr.sr_hdemo_sk, sr.sr_store_sk
),
full_joined AS (
    SELECT
        COALESCE(sale.hd_demo_sk, ret.hd_demo_sk) AS hd_demo_sk,
        sale.cs_promo_sk,
        ret.store_sk,
        sale.total_sales,
        ret.total_returns
    FROM sales_agg sale
    FULL OUTER JOIN returns_agg ret
        ON sale.hd_demo_sk = ret.hd_demo_sk
)
SELECT
    hd_demo_sk,
    cs_promo_sk,
    store_sk,
    total_sales,
    total_returns,
    COALESCE(total_sales, 0) - COALESCE(total_returns, 0) AS net_sales,
    RANK() OVER (ORDER BY COALESCE(total_sales, 0) - COALESCE(total_returns, 0) DESC) AS sales_rank,
    (SELECT COUNT(DISTINCT p.p_promo_sk) FROM promotion p) AS total_promo_count
FROM full_joined
WHERE (COALESCE(total_sales, 0) - COALESCE(total_returns, 0)) > 5000
ORDER BY net_sales DESC
LIMIT 100
