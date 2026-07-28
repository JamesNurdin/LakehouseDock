WITH sales_by_store AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_city,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND p.p_channel_email = 'Y'
      AND s.s_city LIKE 'A%'
    GROUP BY ss.ss_store_sk, s.s_store_name, s.s_city
)

SELECT
    sb.s_store_name,
    sb.s_city,
    CONCAT(sb.s_store_name, ' - ', sb.s_city) AS store_full_name,
    SUBSTR(sb.s_city, 1, 3) AS city_prefix,
    sb.total_net_profit,
    sb.sales_cnt,
    (SELECT AVG(total_net_profit) FROM sales_by_store) AS avg_store_profit,
    (SELECT COUNT(*)
     FROM store_returns sr
     JOIN reason r
         ON sr.sr_reason_sk = r.r_reason_sk
     WHERE sr.sr_store_sk = sb.ss_store_sk
       AND regexp_like(r.r_reason_desc, '(?i)damage')
    ) AS damage_return_cnt
FROM sales_by_store sb
ORDER BY sb.total_net_profit DESC
LIMIT 100
