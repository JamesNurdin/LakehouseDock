WITH ss_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS sales_txns
    FROM store_sales
    WHERE ss_quantity > 0
      AND ss_net_paid > 0
    GROUP BY ss_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    p.p_promo_name,
    c.c_customer_id,
    ca.ca_state,
    cd.cd_gender,
    cs.cs_wholesale_cost,
    sr.sr_return_amt,
    wr.wr_return_amt,
    ss_agg.total_net_paid,
    ss_agg.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss_agg.total_net_paid DESC) AS category_rank
FROM item AS i
JOIN promotion AS p
    ON p.p_item_sk = i.i_item_sk
JOIN catalog_sales AS cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN customer AS c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address AS ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics AS cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN store_returns AS sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN web_returns AS wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN ss_agg
    ON ss_agg.ss_item_sk = i.i_item_sk
WHERE i.i_current_price > 50
  AND p.p_discount_active = 'Y'
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND cs.cs_wholesale_cost BETWEEN 30 AND 70
ORDER BY i.i_category, category_rank
LIMIT 100
