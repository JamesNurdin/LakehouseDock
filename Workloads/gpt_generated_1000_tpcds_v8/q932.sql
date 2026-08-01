WITH ss_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        ss.ss_cdemo_sk,
        ss.ss_ticket_number,
        cd.cd_gender,
        cd.cd_education_status,
        p.p_promo_name,
        p.p_discount_active,
        s.s_store_id,
        s.s_state,
        s.s_rec_start_date,
        cc.cc_call_center_id,
        cc.cc_mkt_desc
    FROM store_sales ss
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN call_center cc
        ON 1 = 1 -- placeholder for later full outer join
),
promo_array AS (
    SELECT
        p.p_promo_sk,
        ARRAY[ p.p_cost, cs.cs_ext_discount_amt ] AS promo_vals
    FROM promotion p
    LEFT JOIN catalog_sales cs
        ON p.p_promo_sk = cs.cs_promo_sk
),
joined_all AS (
    SELECT
        ssb.ss_ticket_number,
        ssb.s_store_id,
        ssb.s_state,
        ssb.ss_ext_sales_price,
        ssb.ss_net_paid,
        ssb.ss_net_profit,
        ssb.cd_gender,
        ssb.cd_education_status,
        ssb.p_promo_name,
        ssb.p_discount_active,
        ssb.cc_mkt_desc,
        ws.ws_order_number,
        ws.ws_ext_sales_price AS web_ext_sales_price,
        ws.ws_net_paid AS web_net_paid,
        wr.wr_return_quantity,
        ws_site.web_name,
        pa.promo_vals
    FROM ss_base ssb
    FULL OUTER JOIN (
        SELECT
            ws.ws_order_number,
            ws.ws_ext_sales_price,
            ws.ws_net_paid,
            ws.ws_web_site_sk,
            ws.ws_promo_sk
        FROM web_sales ws
        WHERE ws.ws_sold_date_sk BETWEEN 2451911 AND 2451915
    ) ws
        ON ssb.ss_ticket_number = ws.ws_order_number
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN promo_array pa
        ON pa.p_promo_sk = ssb.ss_promo_sk
    WHERE ssb.s_state = 'CA'
      AND ssb.p_discount_active = 'Y'
      AND ssb.s_rec_start_date >= DATE '2001-01-01'
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_order_number = ssb.ss_ticket_number
      )
)
SELECT
    j.ss_ticket_number,
    j.s_store_id,
    j.s_state,
    j.ss_ext_sales_price,
    j.web_ext_sales_price,
    j.ss_net_paid,
    j.web_net_paid,
    j.wr_return_quantity,
    j.web_name,
    CASE
        WHEN j.p_discount_active = 'Y' THEN 'Promo Active'
        ELSE 'No Promo'
    END AS promo_status,
    ROW_NUMBER() OVER (PARTITION BY j.s_store_id ORDER BY j.ss_net_paid DESC) AS sales_rank,
    val AS promo_val
FROM joined_all j
CROSS JOIN UNNEST(j.promo_vals) AS t(val)
ORDER BY j.ss_net_paid DESC
LIMIT 100
