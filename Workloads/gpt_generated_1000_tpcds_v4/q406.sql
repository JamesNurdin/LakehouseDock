WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_item_desc,
        i.i_current_price,
        CASE
            WHEN regexp_like(i.i_item_desc, '[0-9]{2,}') THEN 'HasDigits'
            ELSE 'NoDigits'
        END AS desc_type,
        concat(i.i_brand, ' - ', i.i_category) AS brand_category
    FROM item i
    WHERE i.i_item_desc LIKE '%steel%'
      AND regexp_like(i.i_item_desc, '^.*[A-Z]{3}.*$')
)
SELECT
    fi.i_item_id,
    fi.i_product_name,
    fi.brand_category,
    s.s_store_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_transactions,
    CASE
        WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_flag,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
        WHERE i2.i_category = fi.i_category
    ) AS avg_category_profit,
    regexp_extract(fi.i_item_desc, '(\\d+)', 1) AS first_number_in_desc
FROM filtered_items fi
JOIN store_sales ss ON ss.ss_item_sk = fi.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451179
  AND (p.p_promo_name IS NULL OR regexp_like(p.p_promo_name, '.*Clearance.*'))
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
          AND regexp_like(p2.p_promo_name, 'Discount')
    )
GROUP BY
    fi.i_item_id,
    fi.i_product_name,
    fi.brand_category,
    s.s_store_name,
    fi.i_category,
    fi.i_item_desc
ORDER BY total_net_profit DESC
LIMIT 100
