WITH base AS (
    SELECT
        td.t_hour,
        hd.hd_buy_potential,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(CASE WHEN cs.cs_quantity > 5 THEN cs.cs_ext_sales_price ELSE 0 END) AS high_qty_sales
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND hd.hd_buy_potential IN ('5001-10000', '>10000')
      AND r.r_reason_desc LIKE '%Did not get it on time%'
      AND ss.ss_ext_tax > 10
    GROUP BY ROLLUP (td.t_hour, hd.hd_buy_potential)
),
agg AS (
    SELECT
        t_hour,
        hd_buy_potential,
        store_net_paid,
        catalog_net_paid,
        web_net_loss,
        distinct_customers,
        high_qty_sales,
        (store_net_paid + catalog_net_paid - web_net_loss) AS total_contribution,
        CASE
            WHEN (store_net_paid + catalog_net_paid) = 0 THEN NULL
            ELSE web_net_loss / (store_net_paid + catalog_net_paid)
        END AS loss_ratio
    FROM base
)
SELECT
    t_hour,
    hd_buy_potential,
    store_net_paid,
    catalog_net_paid,
    web_net_loss,
    distinct_customers,
    high_qty_sales,
    total_contribution,
    loss_ratio
FROM agg
WHERE total_contribution > (
    SELECT AVG(total_contribution) FROM agg
)
ORDER BY total_contribution DESC
LIMIT 100
