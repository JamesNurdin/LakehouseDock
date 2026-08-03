WITH sales_by_address AS (
    SELECT
        ca_state,
        ca_city,
        SUM(cs_net_paid_inc_ship) AS total_net_paid,
        AVG(cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt,
        SUM(CASE WHEN cs_net_profit > 0 THEN cs_net_profit ELSE 0 END) AS profit_positive,
        SUM(CASE WHEN cs_net_profit <= 0 THEN cs_net_profit ELSE 0 END) AS profit_nonpositive
    FROM catalog_sales
    FULL OUTER JOIN customer_address
        ON catalog_sales.cs_bill_addr_sk = customer_address.ca_address_sk
    WHERE
        ca_zip IN ('40587', '49843', '98579')
        AND ca_state IN ('CA', 'TX', 'NY')
        AND cs_quantity BETWEEN 1 AND 10
        AND cs_ext_tax > 5
        AND cs_net_paid_inc_ship_tax < 20000
        AND cs_promo_sk IS NOT NULL
    GROUP BY ca_state, ca_city
)
SELECT
    ca_state,
    SUM(total_net_paid) AS state_total_net_paid,
    AVG(avg_discount) AS state_avg_discount,
    SUM(sales_cnt) AS state_sales_cnt,
    CASE
        WHEN SUM(profit_positive) > SUM(profit_nonpositive) THEN 'PROFITABLE'
        ELSE 'LOSS'
    END AS profit_indicator
FROM sales_by_address
GROUP BY ca_state
HAVING SUM(sales_cnt) > 1000
ORDER BY state_total_net_paid DESC
