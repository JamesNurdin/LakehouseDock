WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
item_attributes AS (
    SELECT i.i_item_sk,
           attr
    FROM item i
    CROSS JOIN UNNEST(ARRAY[i.i_color, i.i_size]) AS t(attr)
),
ticket_intersect AS (
    SELECT ss_ticket_number FROM store_sales
    INTERSECT
    SELECT sr_ticket_number FROM store_returns
),
base AS (
    SELECT
        ss.ss_ticket_number,
        d.d_year,
        t.t_hour,
        i.i_brand,
        s.s_state,
        p.p_discount_active,
        r.r_reason_desc,
        w.w_warehouse_name,
        cp.cp_department,
        ca.ca_state,
        cd.cd_gender,
        ia.attr,
        ss.ss_quantity,
        ss.ss_net_paid,
        CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_category
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN item_attributes ia ON i.i_item_sk = ia.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk AND i.i_item_sk = inv.inv_item_sk
    LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_page cp ON d.d_date_sk = cp.cp_start_date_sk OR d.d_date_sk = cp.cp_end_date_sk
    LEFT JOIN web_returns wr ON ss.ss_item_sk = wr.wr_item_sk AND d.d_date_sk = wr.wr_returned_date_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE ss.ss_ticket_number IN (SELECT ss_ticket_number FROM ticket_intersect)
      AND d.d_moy = 11
      AND t.t_hour BETWEEN 8 AND 12
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND (r.r_reason_id = 'AAAAAAAABBAAAAAA' OR r2.r_reason_id = 'AAAAAAAABBAAAAAA')
)
SELECT
    d_year,
    region_category,
    COUNT(DISTINCT ss_ticket_number) AS ticket_cnt,
    SUM(ss_quantity) AS total_quantity,
    AVG(ss_net_paid) AS avg_net_paid,
    MAX(ss_net_paid) AS max_net_paid
FROM base
WHERE region_category = 'West'
GROUP BY d_year, region_category

UNION

SELECT
    d_year,
    region_category,
    COUNT(DISTINCT ss_ticket_number) AS ticket_cnt,
    SUM(ss_quantity) AS total_quantity,
    AVG(ss_net_paid) AS avg_net_paid,
    MAX(ss_net_paid) AS max_net_paid
FROM base
WHERE region_category = 'Other'
GROUP BY d_year, region_category
ORDER BY d_year DESC, region_category
LIMIT 100
