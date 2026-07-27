WITH item_returns AS (
    SELECT
        cr_item_sk,
        cr_returning_customer_sk,
        cr_returning_hdemo_sk,
        cr_returning_addr_sk,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 20
      AND cr_return_tax > 0
    GROUP BY cr_item_sk, cr_returning_customer_sk, cr_returning_hdemo_sk, cr_returning_addr_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    ir.total_return_amount,
    ir.avg_return_tax,
    ir.return_cnt,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    c.c_customer_id,
    c.c_preferred_cust_flag,
    ca.ca_state,
    hd.hd_buy_potential,
    RANK() OVER (PARTITION BY i.i_current_price ORDER BY ir.total_return_amount DESC) AS price_bucket_rank,
    (
        SELECT COUNT(DISTINCT cr2.cr_returning_customer_sk)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 20
    ) AS distinct_returning_customers
FROM item_returns ir
JOIN item i
    ON ir.cr_item_sk = i.i_item_sk
JOIN customer c
    ON ir.cr_returning_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ir.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
    ON ir.cr_returning_addr_sk = ca.ca_address_sk
WHERE i.i_current_price > 50
  AND ib.ib_upper_bound <= 100000
  AND c.c_preferred_cust_flag = 'Y'
ORDER BY ir.total_return_amount DESC
LIMIT 100
