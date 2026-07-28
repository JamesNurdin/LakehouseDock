/* goal: Identify the top 100 stores (whose names start with 'A') that generate high profit from items whose product name contains a three‑digit code. The query extracts the numeric code with REGEXP_EXTRACT, shows a product name prefix, filters to items that are tied to an active promotion (using a DISTINCT subquery), ensures the store's average profit exceeds the overall average profit (scalar sub‑query), and only keeps stores whose total profit is greater than 5,000 (HAVING). Results are ordered by total profit descending. */
WITH store_profit AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count,
        AVG(ss.ss_net_profit) AS avg_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '[0-9]{3}')
      AND s.s_store_name LIKE 'A%'
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name
    HAVING SUM(ss.ss_net_profit) > 5000
)
SELECT
    sp.s_store_id,
    sp.s_store_name,
    sp.total_profit,
    sp.txn_count,
    sp.avg_profit,
    regexp_extract(i.i_product_name, '([0-9]{3})') AS product_code,
    substring(i.i_product_name, 1, 5) AS product_prefix,
    concat(s.s_city, ', ', s.s_state) AS location
FROM store_profit sp
JOIN store s ON sp.s_store_sk = s.s_store_sk
JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE sp.avg_profit > (
        SELECT avg(ss2.ss_net_profit)
        FROM store_sales ss2
      )
  AND i.i_item_sk IN (
        SELECT DISTINCT p.p_item_sk
        FROM promotion p
        WHERE p.p_discount_active = 'Y'
      )
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
          AND regexp_like(p2.p_promo_name, '^Clearance.*')
      )
ORDER BY sp.total_profit DESC
LIMIT 100
