WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_current_price,
        i.i_brand_id,
        p.p_promo_id,
        p.p_channel_dmail,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        ss.ss_net_paid,
        ss.ss_ext_tax,
        ca.ca_country,
        sr.sr_return_amt,
        wr.wr_return_amt,
        cp.cp_catalog_page_id,
        wp.wp_url,
        r.r_reason_desc
    FROM store_sales ss
    RIGHT OUTER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
        OR r.r_reason_sk = wr.wr_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
)
SELECT
    d_year,
    i_category,
    SUM(total_net_paid) AS sum_net_paid,
    AVG(avg_tax) AS avg_tax_per_group,
    COUNT(DISTINCT p_promo_id) AS distinct_promos
FROM (
    SELECT
        d_year,
        i_category,
        ss_net_paid AS total_net_paid,
        ss_ext_tax AS avg_tax,
        p_promo_id,
        p_channel_dmail,
        w_warehouse_sq_ft,
        i_current_price,
        ca_country,
        i_brand_id
    FROM base
    WHERE
        p_channel_dmail = 'Y'
        AND w_warehouse_sq_ft > 500000
        AND i_current_price BETWEEN 50 AND 500
        AND d_year BETWEEN 1998 AND 2000
        AND ca_country = 'United States'
        AND i_brand_id = (
            SELECT MAX(i2.i_brand_id)
            FROM item i2
            WHERE i2.i_category = base.i_category
        )
) sub
GROUP BY GROUPING SETS
    ((d_year, i_category),
     (d_year),
     (i_category))
HAVING SUM(total_net_paid) > 10000
ORDER BY sum_net_paid DESC
LIMIT 100
