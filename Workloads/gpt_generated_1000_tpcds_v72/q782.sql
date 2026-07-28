WITH base AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_brand,
        ss.ss_net_paid,
        cs.cs_net_paid,
        cr.cr_net_loss,
        wr.wr_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_size = 'medium'
      AND s.s_state = 'CA'
),
agg AS (
    SELECT
        d_year,
        s_state,
        i_brand,
        SUM(ss_net_paid) AS total_store_sales,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(cr_net_loss) AS total_return_loss,
        SUM(wr_net_loss) AS total_web_return_loss
    FROM base
    GROUP BY GROUPING SETS (
        (d_year, s_state, i_brand),
        (d_year, s_state),
        (d_year),
        ()
    )
)
SELECT
    d_year,
    s_state,
    i_brand,
    total_store_sales,
    total_catalog_sales,
    total_return_loss,
    total_web_return_loss,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_store_sales DESC) AS sales_rank
FROM agg
ORDER BY d_year, s_state, i_brand
LIMIT 100
