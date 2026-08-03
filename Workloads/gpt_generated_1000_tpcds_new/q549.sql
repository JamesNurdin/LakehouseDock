WITH
  sr_base AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_store_sk,
      sr.sr_addr_sk,
      sr.sr_reason_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      i.i_item_id,
      i.i_product_name,
      s.s_store_name,
      r.r_reason_desc,
      ca.ca_city,
      ca.ca_state,
      p.p_promo_name,
      split(p.p_channel_details, ',') AS promo_channels
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
  ),
  sr_unnested AS (
    SELECT
      sr_base.*,
      channel AS promo_channel
    FROM sr_base
    CROSS JOIN UNNEST(sr_base.promo_channels) AS t(channel)
  ),
  wr_base AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_reason_sk,
      wr.wr_refunded_addr_sk,
      wr.wr_returning_addr_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_net_loss,
      i.i_item_id,
      i.i_product_name,
      r.r_reason_desc,
      ca_refund.ca_city AS refund_city,
      ca_refund.ca_state AS refund_state,
      ca_return.ca_city AS returning_city,
      ca_return.ca_state AS returning_state
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
  ),
  full_combined AS (
    SELECT
      COALESCE(sr.sr_returned_date_sk, wr.wr_returned_date_sk) AS return_date_sk,
      COALESCE(sr.sr_item_sk, wr.wr_item_sk) AS item_sk,
      COALESCE(sr.sr_store_sk, -1) AS store_sk,
      COALESCE(sr.sr_return_quantity, 0) AS store_return_qty,
      COALESCE(wr.wr_return_quantity, 0) AS web_return_qty,
      COALESCE(sr.sr_return_amt, 0) AS store_return_amt,
      COALESCE(wr.wr_return_amt, 0) AS web_return_amt,
      COALESCE(sr.sr_net_loss, 0) AS store_net_loss,
      COALESCE(wr.wr_net_loss, 0) AS web_net_loss,
      sr.i_item_id AS store_item_id,
      wr.i_item_id AS web_item_id,
      sr.promo_channel,
      sr.r_reason_desc AS store_reason,
      wr.r_reason_desc AS web_reason,
      sr.ca_city AS store_city,
      wr.refund_city,
      sr.s_store_name,
      wr.returning_city
    FROM sr_unnested sr
    FULL OUTER JOIN wr_base wr
      ON sr.sr_item_sk = wr.wr_item_sk
     AND sr.sr_returned_date_sk = wr.wr_returned_date_sk
  ),
  sr_keys AS (
    SELECT sr.sr_item_sk AS item_sk, sr.sr_returned_date_sk AS date_sk
    FROM store_returns sr
  ),
  wr_keys AS (
    SELECT wr.wr_item_sk AS item_sk, wr.wr_returned_date_sk AS date_sk
    FROM web_returns wr
  ),
  sr_not_in_wr AS (
    SELECT item_sk, date_sk
    FROM sr_keys
    EXCEPT
    SELECT item_sk, date_sk
    FROM wr_keys
  ),
  wr_not_in_sr AS (
    SELECT item_sk, date_sk
    FROM wr_keys
    EXCEPT
    SELECT item_sk, date_sk
    FROM sr_keys
  ),
  common_keys AS (
    SELECT item_sk, date_sk
    FROM sr_keys
    INTERSECT
    SELECT item_sk, date_sk
    FROM wr_keys
  )
SELECT
  fc.return_date_sk,
  fc.item_sk,
  fc.store_sk,
  fc.store_item_id,
  fc.web_item_id,
  fc.store_return_qty,
  fc.web_return_qty,
  fc.store_return_amt,
  fc.web_return_amt,
  fc.store_net_loss,
  fc.web_net_loss,
  CASE
    WHEN fc.store_net_loss > 1000 THEN 'High'
    WHEN fc.store_net_loss > 0   THEN 'Medium'
    ELSE 'Low'
  END AS store_loss_category,
  fc.promo_channel,
  (
    SELECT SUM(sr2.sr_net_loss)
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = fc.store_sk
  ) AS total_store_loss,
  (
    SELECT COUNT(*)
    FROM sr_not_in_wr nin
    WHERE nin.item_sk = fc.item_sk
  ) AS sr_missing_in_web_flag,
  (
    SELECT COUNT(*)
    FROM wr_not_in_sr nin
    WHERE nin.item_sk = fc.item_sk
  ) AS wr_missing_in_store_flag,
  (
    SELECT COUNT(*)
    FROM common_keys ck
    WHERE ck.item_sk = fc.item_sk
  ) AS common_key_count
FROM full_combined fc
ORDER BY fc.return_date_sk DESC, fc.store_net_loss DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
