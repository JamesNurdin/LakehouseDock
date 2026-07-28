WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_brand,
        i_manufact,
        i_item_desc,
        CONCAT(i_brand, ' ', i_manufact) AS brand_manufact,
        regexp_extract(i_item_desc, '(\\d{2})', 1) AS two_digit_code
    FROM item
    WHERE regexp_like(i_item_desc, '\\d{2}')
      AND i_brand LIKE 'A%'
),
store_agg AS (
    SELECT
        fi.i_item_sk,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        COUNT(*) AS store_transactions
    FROM filtered_items fi
    JOIN store_sales ss ON ss.ss_item_sk = fi.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential IN ('>10000', '5001-10000')
    GROUP BY fi.i_item_sk, d.d_year
),
web_agg AS (
    SELECT
        fi.i_item_sk,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        COUNT(*) AS web_transactions
    FROM filtered_items fi
    JOIN web_sales ws ON ws.ws_item_sk = fi.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential IN ('>10000', '5001-10000')
    GROUP BY fi.i_item_sk, d.d_year
)
SELECT
    fi.i_product_name,
    fi.brand_manufact,
    SUBSTRING(fi.i_item_desc FROM 1 FOR 15) AS short_desc,
    fi.two_digit_code,
    COALESCE(sa.store_sales_total, 0) AS store_sales_total,
    COALESCE(wa.web_sales_total, 0) AS web_sales_total,
    COALESCE(sa.store_sales_total, 0) + COALESCE(wa.web_sales_total, 0) AS total_sales,
    COALESCE(sa.store_transactions, 0) AS store_transactions,
    COALESCE(wa.web_transactions, 0) AS web_transactions,
    COALESCE(sa.d_year, wa.d_year) AS sales_year
FROM filtered_items fi
LEFT JOIN store_agg sa ON fi.i_item_sk = sa.i_item_sk
LEFT JOIN web_agg wa ON fi.i_item_sk = wa.i_item_sk
ORDER BY total_sales DESC
LIMIT 100
