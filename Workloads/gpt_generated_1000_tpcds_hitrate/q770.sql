WITH returns_with_array AS (
    SELECT
        sr_ticket_number,
        sr_store_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_net_loss,
        ARRAY[sr_fee, sr_store_credit, sr_reversed_charge] AS fee_components,
        sr_fee,
        sr_store_credit,
        sr_reversed_charge
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_fee > 10
      AND sr_store_credit < 2000
      AND sr_reversed_charge <> 0
      AND sr_net_loss > 0
      AND sr_return_amt_inc_tax BETWEEN 10 AND 5000
),

sales_filtered AS (
    SELECT
        ss_ticket_number,
        ss_store_sk,
        ss_item_sk,
        ss_quantity,
        ss_ext_sales_price,
        ss_ext_tax,
        ss_coupon_amt,
        ss_net_profit,
        ss_ext_discount_amt
    FROM store_sales
    WHERE ss_coupon_amt > 100
      AND ss_ext_tax > 20
      AND ss_wholesale_cost < 100
      AND ss_net_profit > 0
      AND ss_quantity > 1
      AND ss_ext_sales_price BETWEEN 200 AND 10000
      AND ss_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)
)

SELECT DISTINCT
    r.sr_ticket_number,
    r.sr_store_sk,
    s.ss_store_sk,
    r.sr_item_sk,
    r.sr_return_quantity,
    r.sr_net_loss,
    s.ss_ext_sales_price,
    s.ss_ext_tax,
    s.ss_coupon_amt,
    fee_comp,
    ROW_NUMBER() OVER (PARTITION BY r.sr_store_sk ORDER BY r.sr_net_loss DESC) AS rn_loss_rank,
    DENSE_RANK() OVER (ORDER BY s.ss_ext_sales_price DESC) AS dr_sales_price,
    (SELECT SUM(ss_ext_sales_price)
     FROM store_sales ss_sub
     WHERE ss_sub.ss_ticket_number = s.ss_ticket_number) AS total_sales_per_ticket
FROM returns_with_array r
JOIN sales_filtered s
    ON r.sr_item_sk = s.ss_item_sk
   AND r.sr_ticket_number = s.ss_ticket_number
CROSS JOIN UNNEST(r.fee_components) AS t(fee_comp)
WHERE s.ss_ext_tax > (SELECT AVG(ss_ext_tax) FROM store_sales)
  AND s.ss_coupon_amt < (SELECT MAX(ss_coupon_amt) FROM store_sales)
  AND r.sr_net_loss > (SELECT MIN(sr_net_loss) FROM store_returns)
  AND s.ss_quantity <= (SELECT MAX(ss_quantity) FROM store_sales)
  AND r.sr_store_sk <> (SELECT sr_store_sk FROM store_returns ORDER BY sr_store_sk LIMIT 1)
  AND s.ss_store_sk = r.sr_store_sk
ORDER BY r.sr_store_sk, rn_loss_rank
LIMIT 100
