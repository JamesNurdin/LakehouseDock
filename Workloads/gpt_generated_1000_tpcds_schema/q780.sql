WITH hd_income AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    FULL OUTER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
store_cust AS (
    SELECT DISTINCT c.c_customer_id
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN hd_income hdi ON hd.hd_demo_sk = hdi.hd_demo_sk
    WHERE i.i_class = 'shirts'
      AND sr.sr_return_amt > 100
      AND p.p_discount_active = 'Y'
      AND hdi.ib_upper_bound > 50000
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_response_target = 1
      )
),
web_cust AS (
    SELECT DISTINCT c.c_customer_id
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN hd_income hdi ON hd.hd_demo_sk = hdi.hd_demo_sk
    WHERE i.i_class = 'shirts'
      AND wr.wr_return_amt > 100
      AND p.p_discount_active = 'Y'
      AND hdi.ib_upper_bound > 50000
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_response_target = 1
      )
),
common_cust AS (
    SELECT c_customer_id FROM store_cust
    INTERSECT
    SELECT c_customer_id FROM web_cust
),
high_loss_cust AS (
    SELECT DISTINCT c.c_customer_id
    FROM customer c
    JOIN LATERAL (
        SELECT SUM(sr.sr_net_loss) AS total_loss
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
    ) sl ON TRUE
    WHERE sl.total_loss > 1000
)
SELECT c_customer_id
FROM common_cust
UNION
SELECT c_customer_id
FROM high_loss_cust
ORDER BY c_customer_id
LIMIT 100
