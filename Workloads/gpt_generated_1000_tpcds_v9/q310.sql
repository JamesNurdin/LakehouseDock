WITH sales_agg AS (
    SELECT
        ca.ca_state,
        hd.hd_demo_sk,
        SUM(cs.cs_net_paid) AS sum_cs_net_paid,
        SUM(cs.cs_net_profit) AS sum_cs_net_profit,
        COUNT(DISTINCT cs.cs_bill_addr_sk) AS distinct_bill_addr_cnt
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_wholesale_cost BETWEEN 40 AND 80
      AND cs.cs_ext_ship_cost > 500
      AND ca.ca_state IN ('TX', 'CA', 'NY', 'FL', 'WA')
      AND hd.hd_dep_count >= 1
    GROUP BY ca.ca_state, hd.hd_demo_sk
),
store_sales_agg AS (
    SELECT
        hd.hd_demo_sk,
        SUM(ss.ss_net_profit) AS total_ss_net_profit
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_quantity > 0
      AND ss.ss_net_paid > 1000
      AND ca.ca_state IN ('TX', 'CA', 'NY', 'FL', 'WA')
    GROUP BY hd.hd_demo_sk
),
web_returns_agg AS (
    SELECT
        hd.hd_demo_sk,
        SUM(wr.wr_net_loss) AS total_wr_net_loss
    FROM web_returns wr
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
      AND ca.ca_state IN ('TX', 'CA', 'NY', 'FL', 'WA')
    GROUP BY hd.hd_demo_sk
)
SELECT
    sa.ca_state AS state,
    sa.hd_demo_sk AS household_demo_key,
    sa.sum_cs_net_paid,
    sa.sum_cs_net_profit,
    COALESCE(ssa.total_ss_net_profit, 0) AS total_store_net_profit,
    COALESCE(wra.total_wr_net_loss, 0) AS total_web_net_loss,
    (sa.sum_cs_net_profit + COALESCE(ssa.total_ss_net_profit, 0) - COALESCE(wra.total_wr_net_loss, 0)) AS overall_net_contribution
FROM sales_agg sa
LEFT JOIN store_sales_agg ssa ON ssa.hd_demo_sk = sa.hd_demo_sk
LEFT JOIN web_returns_agg wra ON wra.hd_demo_sk = sa.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss2
    JOIN household_demographics hd2 ON ss2.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON ss2.ss_addr_sk = ca2.ca_address_sk
    WHERE hd2.hd_demo_sk = sa.hd_demo_sk
      AND ss2.ss_net_profit > 1000
      AND ca2.ca_state = sa.ca_state
)
ORDER BY overall_net_contribution DESC
LIMIT 100
