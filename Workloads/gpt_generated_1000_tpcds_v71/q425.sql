WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        i.i_category,
        i.i_brand,
        i.i_formulation,
        ca.ca_state AS address_state,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_state AS store_state,
        sr.sr_return_quantity,
        sr.sr_return_amt
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE ib.ib_lower_bound >= 30000
      AND ib.ib_upper_bound <= 120000
      AND i.i_formulation LIKE '%steel%'
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND s.s_state = 'CA'
      AND cs.cs_quantity >= 2
),
agg AS (
    SELECT
        i_category,
        i_brand,
        store_state,
        CASE
            WHEN ib_upper_bound <= 50000 THEN 'Low Income'
            WHEN ib_upper_bound <= 100000 THEN 'Mid Income'
            ELSE 'High Income'
        END AS income_segment,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid,
        AVG(cs_net_profit) AS avg_net_profit,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_return_qty,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount
    FROM base
    GROUP BY i_category,
        i_brand,
        store_state,
        CASE
            WHEN ib_upper_bound <= 50000 THEN 'Low Income'
            WHEN ib_upper_bound <= 100000 THEN 'Mid Income'
            ELSE 'High Income'
        END
    HAVING SUM(cs_net_paid) > 10000
)
SELECT
    i_category,
    i_brand,
    store_state,
    income_segment,
    orders_cnt,
    total_quantity,
    total_net_paid,
    avg_net_profit,
    total_return_qty,
    total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY store_state ORDER BY total_net_paid DESC) AS rn_state_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
