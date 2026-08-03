WITH ss_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_customer_sk,
        ss_promo_sk,
        SUM(ss_net_paid)          AS ss_total_paid,
        SUM(ss_quantity)          AS ss_total_qty
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_customer_sk, ss_promo_sk
)
SELECT
    d_year,
    cd_gender,
    ca_state,
    SUM(total_sales)    AS total_sales,
    SUM(total_quantity) AS total_quantity
FROM (
    SELECT
        d1.d_year,
        cd.cd_gender,
        ca.ca_state,
        (
            COALESCE(ss_total_paid, 0) +
            COALESCE(cs.cs_ext_sales_price, 0) +
            COALESCE(ws.ws_ext_sales_price, 0)
        )                     AS total_sales,
        (
            COALESCE(ss_total_qty, 0) +
            COALESCE(cs.cs_quantity, 0) +
            COALESCE(ws.ws_quantity, 0)
        )                     AS total_quantity
    FROM ss_agg
    JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d1 ON ss_agg.ss_sold_date_sk = d1.d_date_sk
    LEFT JOIN promotion p ON ss_agg.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
                                AND cs.cs_sold_date_sk = d1.d_date_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                             AND ws.ws_sold_date_sk = d1.d_date_sk
    LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    FULL OUTER JOIN date_dim d_full ON cp.cp_end_date_sk = d_full.d_date_sk
    WHERE d1.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND cs.cs_quantity > 1
) sub
GROUP BY ROLLUP (d_year, cd_gender, ca_state)
ORDER BY d_year DESC NULLS LAST, cd_gender, ca_state
LIMIT 100
