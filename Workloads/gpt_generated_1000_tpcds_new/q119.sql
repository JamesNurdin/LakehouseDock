WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_category,
        i_brand,
        i_item_desc,
        i_product_name,
        i_current_price,
        regexp_extract(i_item_desc, '(\\d{4})') AS extracted_year,
        CASE
            WHEN regexp_like(i_item_desc, '[A-Z]{2}') THEN 'HAS_TWO_CAPS'
            ELSE 'NO_CAPS'
        END AS desc_type
    FROM item
    WHERE regexp_like(i_item_desc, '\\d{4}')
      AND i_product_name LIKE '%Deluxe%'
)
SELECT
    fi.i_category,
    fi.i_brand,
    fi.extracted_year,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS positive_profit,
    SUM(CASE WHEN cs.cs_net_profit < 0 THEN cs.cs_net_profit ELSE 0 END) AS negative_profit,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    CONCAT(fi.i_brand, ' ', fi.i_category) AS brand_category,
    fi.desc_type
FROM filtered_items fi
JOIN catalog_sales cs ON cs.cs_item_sk = fi.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = fi.i_item_sk
WHERE p.p_promo_name LIKE '%Summer%'
  AND regexp_like(p.p_promo_name, '^[A-Z]{3}[0-9]{2}$')
GROUP BY
    fi.i_category,
    fi.i_brand,
    fi.extracted_year,
    fi.desc_type
ORDER BY total_profit DESC
LIMIT 100
