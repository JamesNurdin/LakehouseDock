WITH
    returns_union AS (
        SELECT sr.sr_returned_date_sk AS return_date_sk,
               sr.sr_item_sk          AS item_sk,
               sr.sr_net_loss        AS net_loss,
               'store'                AS source
        FROM   store_returns sr
        UNION DISTINCT
        SELECT wr.wr_returned_date_sk AS return_date_sk,
               wr.wr_item_sk          AS item_sk,
               wr.wr_net_loss        AS net_loss,
               'web'                  AS source
        FROM   web_returns wr
    ),
    intersect_items AS (
        SELECT DISTINCT p.p_item_sk AS item_sk
        FROM   promotion p
        WHERE  regexp_like(p.p_promo_name, '(?i)sale')
        INTERSECT
        SELECT DISTINCT ru.item_sk FROM returns_union ru
    ),
    except_items AS (
        SELECT i.i_item_sk AS item_sk
        FROM   item i
        EXCEPT
        SELECT p.p_item_sk FROM promotion p
    ),
    filtered_returns AS (
        SELECT ru.return_date_sk,
               ru.item_sk,
               ru.net_loss,
               ru.source
        FROM   returns_union ru
        WHERE  ru.item_sk IN (SELECT item_sk FROM intersect_items)
          AND  ru.item_sk NOT IN (SELECT item_sk FROM except_items)
    )
SELECT
    d.d_year,
    d.d_quarter_name,
    p.p_purpose,
    CONCAT(CAST(d.d_year AS varchar), '-', p.p_purpose)                     AS year_purpose,
    COUNT(DISTINCT f.item_sk)                                                AS distinct_items,
    SUM(f.net_loss)                                                          AS total_net_loss,
    MAX(REGEXP_EXTRACT(i.i_product_name, '(\\d{3,})', 1))                  AS product_code,
    MAX(CASE WHEN i.i_product_name LIKE '%Large%' THEN 'Large' ELSE 'Other' END) AS size_category,
    MAX(SUBSTRING(i.i_product_name, 1, 10))                                 AS short_name
FROM   filtered_returns f
       JOIN date_dim d ON f.return_date_sk = d.d_date_sk
       JOIN item i ON f.item_sk = i.i_item_sk
       JOIN promotion p ON i.i_item_sk = p.p_item_sk
GROUP BY ROLLUP (d.d_year, d.d_quarter_name, p.p_purpose)
ORDER BY d.d_year DESC, d.d_quarter_name, p.p_purpose
LIMIT 100
