WITH promo_tokens AS (
   SELECT
       p.p_promo_sk,
       p.p_promo_id,
       token
   FROM promotion p
   CROSS JOIN UNNEST(split(p.p_channel_details, ' ')) AS t (token)
   WHERE p.p_channel_dmail = 'Y'
),
base_sales AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_store_sk,
       ss.ss_item_sk,
       ss.ss_promo_sk,
       ss.ss_quantity,
       ss.ss_net_paid,
       ss.ss_ticket_number,
       p.p_promo_id,
       p.p_channel_dmail,
       p.p_channel_radio
   FROM store_sales ss
   FULL OUTER JOIN promotion p
       ON ss.ss_promo_sk = p.p_promo_sk
   WHERE ss.ss_quantity > 1
     AND ss.ss_net_paid >= 10
     AND (p.p_channel_dmail = 'Y' OR p.p_channel_dmail = 'N')
     AND p.p_channel_radio = 'N'
     AND ss.ss_store_sk IN (49, 805, 919)
     AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
),
returns_agg AS (
   SELECT
       sr.sr_item_sk,
       sr.sr_ticket_number,
       SUM(sr.sr_return_amt) AS total_return_amt,
       COUNT(*) AS return_cnt,
       MAX(sr.sr_return_ship_cost) AS max_ship_cost
   FROM store_returns sr
   GROUP BY sr.sr_item_sk, sr.sr_ticket_number
),
unioned AS (
   SELECT
       b.ss_sold_date_sk,
       b.ss_store_sk,
       b.ss_item_sk,
       b.ss_quantity,
       b.ss_net_paid,
       b.p_promo_id,
       b.p_channel_dmail,
       b.p_channel_radio,
       r.total_return_amt,
       r.return_cnt,
       NULL AS token
   FROM base_sales b
   LEFT JOIN returns_agg r
       ON r.sr_item_sk = b.ss_item_sk
      AND r.sr_ticket_number = b.ss_ticket_number
   WHERE r.return_cnt IS NOT NULL

   UNION DISTINCT

   SELECT
       b.ss_sold_date_sk,
       b.ss_store_sk,
       b.ss_item_sk,
       b.ss_quantity,
       b.ss_net_paid,
       b.p_promo_id,
       b.p_channel_dmail,
       b.p_channel_radio,
       0.0 AS total_return_amt,
       0 AS return_cnt,
       pt.token
   FROM base_sales b
   LEFT JOIN promo_tokens pt
       ON pt.p_promo_sk = b.ss_promo_sk
   WHERE b.p_promo_id IS NOT NULL
     AND pt.token IS NOT NULL
)
SELECT
    u.ss_sold_date_sk,
    u.ss_store_sk,
    u.ss_item_sk,
    u.ss_quantity,
    u.ss_net_paid,
    u.p_promo_id,
    u.p_channel_dmail,
    u.p_channel_radio,
    u.total_return_amt,
    u.return_cnt,
    u.token,
    ROW_NUMBER() OVER (PARTITION BY u.ss_store_sk ORDER BY u.ss_net_paid DESC) AS rn_store_sales,
    RANK() OVER (ORDER BY u.total_return_amt DESC) AS rank_return_amt,
    (SELECT SUM(sr2.sr_return_amt)
     FROM store_returns sr2
     WHERE sr2.sr_store_sk = u.ss_store_sk) AS store_total_return_amt
FROM unioned u
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr3
    WHERE sr3.sr_item_sk = u.ss_item_sk
      AND sr3.sr_return_amt > 5
)
ORDER BY u.ss_net_paid DESC, u.ss_sold_date_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
