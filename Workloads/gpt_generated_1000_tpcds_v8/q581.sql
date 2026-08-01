WITH ws AS (
    SELECT
        ws.ws_item_sk,
        i.i_product_name,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        cd.cd_credit_rating,
        wp.wp_url
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(i.i_product_name, 'Premium|Deluxe')
      AND cd.cd_credit_rating LIKE '%Risk%'
      AND wp.wp_url LIKE 'http://%'
),
sr AS (
    SELECT
        sr.sr_item_sk,
        i.i_product_name,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_ship_cost,
        cd.cd_credit_rating,
        sr.sr_ticket_number
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_return_ship_cost > 50
      AND regexp_extract(i.i_item_desc, '(\\w+)-\\w+', 1) = 'Electronic'
),
union_set AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.i_product_name AS product_name,
        ws.ws_sales_price AS amount,
        ws.ws_ext_discount_amt AS discount,
        ws.ws_net_profit AS profit,
        'web' AS source
    FROM ws
    UNION DISTINCT
    SELECT
        sr.sr_item_sk,
        sr.i_product_name,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        NULL AS profit,
        'store' AS source
    FROM sr
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY amount DESC) AS rn
    FROM union_set
),
final AS (
    SELECT
        r.item_sk,
        r.product_name,
        r.amount,
        r.discount,
        r.profit,
        r.source,
        r.rn,
        (SELECT COUNT(*) FROM sr s2 WHERE s2.sr_item_sk = r.item_sk) AS related_store_return_cnt
    FROM ranked r
    WHERE r.rn > 10
)
SELECT DISTINCT
    f.item_sk,
    f.product_name,
    f.amount,
    f.discount,
    f.profit,
    f.source,
    f.rn,
    f.related_store_return_cnt,
    CONCAT(f.product_name, '_', f.source) AS label,
    SUBSTRING(f.product_name, 1, 10) AS short_name
FROM final f
EXCEPT
SELECT
    item_sk,
    product_name,
    amount,
    discount,
    profit,
    source,
    rn,
    related_store_return_cnt,
    CONCAT(product_name, '_', source),
    SUBSTRING(product_name, 1, 10)
FROM final
WHERE source = 'store'
ORDER BY amount DESC
OFFSET 20
LIMIT 100
