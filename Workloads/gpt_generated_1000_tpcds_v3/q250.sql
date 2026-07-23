WITH filtered_items AS (
    SELECT i_item_sk, i_category, i_brand
    FROM item
    WHERE i_current_price BETWEEN 10.00 AND 100.00
)
SELECT
    fi.i_category,
    fi.i_brand,
    'Web' AS channel,
    SUM(ws.ws_ext_sales_price) AS total_amount,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS amount_level
FROM web_sales ws
JOIN filtered_items fi
    ON ws.ws_item_sk = fi.i_item_sk
WHERE ws.ws_net_paid_inc_ship_tax > 500
GROUP BY fi.i_category, fi.i_brand

UNION ALL

SELECT
    fi.i_category,
    fi.i_brand,
    'Store' AS channel,
    SUM(sr.sr_return_amt) AS total_amount,
    CASE WHEN SUM(sr.sr_return_amt) > 5000 THEN 'High' ELSE 'Low' END AS amount_level
FROM store_returns sr
JOIN filtered_items fi
    ON sr.sr_item_sk = fi.i_item_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_net_loss > 0
GROUP BY fi.i_category, fi.i_brand

ORDER BY channel, total_amount DESC
LIMIT 100
