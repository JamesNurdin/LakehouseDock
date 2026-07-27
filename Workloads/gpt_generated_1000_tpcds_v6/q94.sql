WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_promo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_profit > 0
      AND cs.cs_ext_discount_amt > 0
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451200
)
SELECT
    p.p_promo_id,
    ca.ca_state,
    SUM(fs.cs_net_profit) AS total_net_profit,
    SUM(fs.cs_quantity) AS total_quantity,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT fs.cs_bill_cdemo_sk) AS distinct_customer_demo,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(fs.cs_net_profit) DESC) AS profit_rank_state,
    SUM(SUM(fs.cs_net_profit)) OVER (
        PARTITION BY ca.ca_state
        ORDER BY SUM(fs.cs_net_profit) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_state
FROM filtered_sales fs
JOIN promotion p
    ON fs.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca
    ON fs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON fs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE p.p_cost > 500
  AND p.p_channel_catalog = 'N'
  AND cd.cd_dep_count >= 2
  AND cd.cd_dep_employed_count >= 1
  AND hd.hd_vehicle_count >= 1
  AND ca.ca_country = 'United States'
GROUP BY
    p.p_promo_id,
    ca.ca_state
ORDER BY total_net_profit DESC
LIMIT 100
