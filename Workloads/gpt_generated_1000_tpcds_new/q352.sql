WITH sales_agg AS (
    SELECT
        cp.cp_department,
        cs.cs_bill_customer_sk,
        SUM(cs.cs_net_profit) AS dept_total_profit,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs.cs_net_profit) DESC) AS dept_profit_rank
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_wholesale_cost > 10
    GROUP BY cp.cp_department, cs.cs_bill_customer_sk
)
SELECT
    cp.cp_department,
    cs.cs_order_number,
    cs.cs_net_paid_inc_ship_tax,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    ws.ws_net_profit,
    r.total_return_amt,
    CASE WHEN EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_net_loss > 0
    ) THEN 1 ELSE 0 END AS has_lossful_return,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_paid_inc_ship_tax DESC) AS dept_sales_rank,
    sa.dept_total_profit,
    sa.dept_profit_rank
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
                       AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN LATERAL (
    SELECT SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    WHERE wr.wr_order_number = ws.ws_order_number
) r ON true
JOIN sales_agg sa ON sa.cs_bill_customer_sk = cs.cs_bill_customer_sk
                 AND sa.cp_department = cp.cp_department
WHERE cs.cs_wholesale_cost > 20
  AND cs.cs_ext_sales_price > 1000
  AND cd.cd_credit_rating = 'Good'
  AND hd.hd_buy_potential = 'HIGH'

UNION DISTINCT

SELECT
    cp2.cp_department,
    NULL AS cs_order_number,
    NULL AS cs_net_paid_inc_ship_tax,
    cd2.cd_credit_rating,
    hd2.hd_buy_potential,
    NULL AS ws_net_profit,
    0 AS total_return_amt,
    0 AS has_lossful_return,
    NULL AS dept_sales_rank,
    sa2.dept_total_profit,
    sa2.dept_profit_rank
FROM catalog_page cp2
RIGHT OUTER JOIN catalog_sales cs2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
JOIN customer_demographics cd2 ON cs2.cs_bill_cdemo_sk = cd2.cd_demo_sk
JOIN household_demographics hd2 ON cs2.cs_bill_hdemo_sk = hd2.hd_demo_sk
LEFT JOIN web_sales ws2 ON ws2.ws_bill_cdemo_sk = cd2.cd_demo_sk
                         AND ws2.ws_bill_hdemo_sk = hd2.hd_demo_sk
LEFT JOIN LATERAL (
    SELECT SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    WHERE wr.wr_order_number = ws2.ws_order_number
) r2 ON true
JOIN sales_agg sa2 ON sa2.cs_bill_customer_sk = cs2.cs_bill_customer_sk
                    AND sa2.cp_department = cp2.cp_department
WHERE cs2.cs_wholesale_cost > 20
  AND cs2.cs_ext_sales_price > 1000
  AND cd2.cd_credit_rating = 'Good'
  AND hd2.hd_buy_potential = 'HIGH'
LIMIT 100
