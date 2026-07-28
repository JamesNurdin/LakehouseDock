WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        d_cs_sold.d_year AS sold_year,
        d_cs_ship.d_year AS ship_year,
        cc.cc_name,
        p.p_discount_active,
        ss.ss_net_profit AS store_profit,
        wr.wr_net_loss,
        CASE
            WHEN cs.cs_net_paid_inc_ship > 10000 THEN 'HIGH'
            WHEN cs.cs_net_paid_inc_ship > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS revenue_band
    FROM catalog_sales cs
    JOIN date_dim d_cs_sold
        ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN date_dim d_cs_ship
        ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_cs_sold.d_date_sk
    JOIN promotion p2
        ON ss.ss_promo_sk = p2.p_promo_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_cs_sold.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    WHERE EXISTS (
        SELECT 1 FROM catalog_sales cs2
        WHERE cs2.cs_order_number = wr.wr_order_number
    )
),
agg AS (
    SELECT
        revenue_band,
        sold_year,
        COUNT(DISTINCT cs_order_number) AS orders,
        SUM(cs_net_paid_inc_ship) AS total_net_paid,
        SUM(store_profit) AS total_store_profit,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(cs_quantity) AS avg_quantity
    FROM base
    GROUP BY ROLLUP (revenue_band, sold_year)
)
SELECT
    revenue_band,
    sold_year,
    orders,
    total_net_paid,
    total_store_profit,
    total_net_loss,
    avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY revenue_band ORDER BY total_net_paid DESC) AS revenue_rank,
    (SELECT AVG(cs_net_paid_inc_ship) FROM catalog_sales) AS overall_avg_net_paid
FROM agg
ORDER BY revenue_band NULLS LAST, sold_year
