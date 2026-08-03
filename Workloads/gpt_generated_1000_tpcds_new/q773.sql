WITH promo_words AS (
        SELECT
            p.p_promo_sk,
            p.p_promo_id,
            p.p_promo_name,
            word
        FROM tpcds.promotion p
        CROSS JOIN UNNEST(split(p.p_promo_name, ' ')) AS t(word)
    ),
    sales_agg AS (
        SELECT
            p.p_promo_sk,
            p.p_promo_id,
            COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_quantity) AS total_quantity,
            MAX(p.p_end_date_sk) AS latest_end_date_sk
        FROM tpcds.promotion p
        JOIN tpcds.store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
        WHERE regexp_like(p.p_promo_name, '^.{3,}$')
        GROUP BY p.p_promo_sk, p.p_promo_id
    ),
    returns_agg AS (
        SELECT
            p.p_promo_sk,
            SUM(sr.sr_return_amt) AS total_return_amount,
            SUM(sr.sr_fee) AS total_fee
        FROM tpcds.promotion p
        JOIN tpcds.store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
        JOIN tpcds.store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                                 AND sr.sr_ticket_number = ss.ss_ticket_number
        WHERE p.p_promo_name LIKE '%Sale%'
        GROUP BY p.p_promo_sk
    ),
    promo_exclusive AS (
        SELECT p.p_promo_sk
        FROM tpcds.promotion p
        JOIN tpcds.store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
        EXCEPT
        SELECT p2.p_promo_sk
        FROM tpcds.promotion p2
        JOIN tpcds.store_sales ss2 ON ss2.ss_promo_sk = p2.p_promo_sk
        JOIN tpcds.store_returns sr2 ON sr2.sr_item_sk = ss2.ss_item_sk
                                     AND sr2.sr_ticket_number = ss2.ss_ticket_number
    )
SELECT
    p.p_promo_id,
    p.p_promo_name,
    pw.word,
    s.tickets_sold,
    s.total_sales,
    r.total_return_amount,
    r.total_fee,
    CASE WHEN pe.p_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS exclusive_to_sales,
    substring(p.p_promo_name, 1, 10) AS promo_name_prefix,
    concat(p.p_promo_name, '_', cast(p.p_promo_sk AS varchar)) AS promo_full_code
FROM tpcds.promotion p
FULL OUTER JOIN sales_agg s ON s.p_promo_sk = p.p_promo_sk
FULL OUTER JOIN returns_agg r ON r.p_promo_sk = p.p_promo_sk
LEFT JOIN promo_words pw ON pw.p_promo_sk = p.p_promo_sk
LEFT JOIN promo_exclusive pe ON pe.p_promo_sk = p.p_promo_sk
WHERE p.p_promo_name IS NOT NULL
UNION
SELECT
    p2.p_promo_id,
    p2.p_promo_name,
    pw2.word,
    s2.tickets_sold,
    s2.total_sales,
    r2.total_return_amount,
    r2.total_fee,
    CASE WHEN pe2.p_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS exclusive_to_sales,
    substring(p2.p_promo_name, 1, 10) AS promo_name_prefix,
    concat(p2.p_promo_name, '_', cast(p2.p_promo_sk AS varchar)) AS promo_full_code
FROM tpcds.promotion p2
FULL OUTER JOIN sales_agg s2 ON s2.p_promo_sk = p2.p_promo_sk
FULL OUTER JOIN returns_agg r2 ON r2.p_promo_sk = p2.p_promo_sk
LEFT JOIN promo_words pw2 ON pw2.p_promo_sk = p2.p_promo_sk
LEFT JOIN promo_exclusive pe2 ON pe2.p_promo_sk = p2.p_promo_sk
WHERE p2.p_promo_name IS NOT NULL
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
