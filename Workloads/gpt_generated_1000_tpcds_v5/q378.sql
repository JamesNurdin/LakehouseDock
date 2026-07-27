/* goal: Compare high‑discount sales from stores and web channels, showing item, promotion and household buying potential, and count of active promotions per item. */
WITH store_part AS (
    SELECT
        'store' AS sales_source,
        ss.ss_sold_date_sk AS sale_date_sk,
        i.i_item_id,
        p.p_promo_name,
        ss.ss_ext_discount_amt AS discount_amt,
        hd.hd_buy_potential,
        (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk AND p2.p_discount_active = 'Y') AS active_promo_count
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_ext_discount_amt > 1000
      AND p.p_channel_email = 'N'
      AND EXISTS (
          SELECT 1 FROM promotion p3 WHERE p3.p_item_sk = i.i_item_sk AND p3.p_discount_active = 'Y'
      )
),
web_part AS (
    SELECT
        'web' AS sales_source,
        ws.ws_sold_date_sk AS sale_date_sk,
        i.i_item_id,
        p.p_promo_name,
        ws.ws_ext_discount_amt AS discount_amt,
        hd.hd_buy_potential,
        (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk AND p2.p_discount_active = 'Y') AS active_promo_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_ext_discount_amt > 1000
      AND p.p_channel_email = 'N'
      AND EXISTS (
          SELECT 1 FROM promotion p3 WHERE p3.p_item_sk = i.i_item_sk AND p3.p_discount_active = 'Y'
      )
)
SELECT *
FROM store_part
UNION ALL
SELECT *
FROM web_part
ORDER BY discount_amt DESC, sale_date_sk DESC
LIMIT 100
