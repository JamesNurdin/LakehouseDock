WITH joined AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_market_id,
        d_cs.d_date AS d_date,
        d_cs.d_year AS d_year,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand_id,
        inv.inv_quantity_on_hand,
        cs.cs_net_paid AS cs_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        web.web_name,
        /* calculate a net total that adds sales and subtracts returns */
        (cs.cs_net_paid + ws.ws_net_paid
         - COALESCE(cr.cr_return_amount, 0)
         - COALESCE(sr.sr_return_amt, 0)
         - COALESCE(wr.wr_return_amt, 0)) AS net_total
    FROM catalog_sales cs
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    /* store-return relationship */
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    /* inventory at the same date as the sale */
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_cs.d_date_sk
    /* catalog return linked by order number */
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    /* web sales linked via item, date and customer */
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_cs.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    /* web returns linked to the web sale */
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE d_cs.d_year = 2001
      AND s.s_market_id IN (3, 5)
      AND i.i_brand_id = 10
)
SELECT
    agg.s_store_sk,
    agg.s_store_name,
    agg.s_market_id,
    agg.d_date,
    agg.d_year,
    agg.net_total,
    RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.net_total DESC) AS yearly_store_rank
FROM (
    SELECT
        s_store_sk,
        s_store_name,
        s_market_id,
        d_date,
        d_year,
        SUM(net_total) AS net_total
    FROM joined
    GROUP BY s_store_sk, s_store_name, s_market_id, d_date, d_year
) agg
ORDER BY agg.d_year, yearly_store_rank
OFFSET 0 LIMIT 100
