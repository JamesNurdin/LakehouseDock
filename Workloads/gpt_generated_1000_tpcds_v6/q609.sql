WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_brand,
        regexp_extract(i_item_desc, '(\\w+)', 1) AS first_word
    FROM
        item
    WHERE
        regexp_like(i_item_desc, '(?i)sport')
)
SELECT
    d.d_year,
    fi.first_word,
    concat(fi.first_word, ' ', fi.i_brand) AS product_label,
    wsit.web_name,
    substring(fi.i_item_desc FROM 1 FOR 20) AS short_desc,
    SUM(ws.ws_net_paid) AS total_sales,
    COUNT(*) AS order_cnt
FROM
    filtered_items fi
JOIN
    web_sales ws
    ON ws.ws_item_sk = fi.i_item_sk
JOIN
    date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN
    promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
    AND p.p_promo_name LIKE '%Clearance%'
JOIN
    web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE
    d.d_year = 2001
GROUP BY
    d.d_year,
    fi.first_word,
    fi.i_brand,
    wsit.web_name,
    fi.i_item_desc
ORDER BY
    total_sales DESC
LIMIT 100
