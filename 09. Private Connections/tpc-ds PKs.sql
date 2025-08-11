
ALTER TABLE reason
ADD CONSTRAINT reason_pk PRIMARY KEY(r_reason_sk);


ALTER TABLE customer
ADD CONSTRAINT customer_pk PRIMARY KEY(c_customer_sk);


ALTER TABLE store_returns
ADD CONSTRAINT store_returns_pk PRIMARY KEY(sr_ticket_number,sr_item_sk);


ALTER TABLE call_center
ADD CONSTRAINT call_center_pk PRIMARY KEY(cc_call_center_sk);


ALTER TABLE web_page
ADD CONSTRAINT web_page_pk PRIMARY KEY(wp_web_page_sk);


ALTER TABLE web_returns
ADD CONSTRAINT web_returns_pk PRIMARY KEY(wr_item_sk,wr_order_number);


ALTER TABLE store
ADD CONSTRAINT store_pk PRIMARY KEY(s_store_sk);


ALTER TABLE warehouse
ADD CONSTRAINT warehouse_pk PRIMARY KEY(w_warehouse_sk);


ALTER TABLE store_sales
ADD CONSTRAINT store_sales_pk PRIMARY KEY(ss_item_sk,ss_ticket_number);


ALTER TABLE income_band
ADD CONSTRAINT income_band_pk PRIMARY KEY(ib_income_band_sk);


ALTER TABLE promotion
ADD CONSTRAINT promotion_pk PRIMARY KEY(p_promo_sk);


ALTER TABLE catalog_returns
ADD CONSTRAINT catalog_returns_pk PRIMARY KEY(cr_item_sk,cr_order_number);


ALTER TABLE time_dim
ADD CONSTRAINT time_dim_pk PRIMARY KEY(t_time_sk);


ALTER TABLE ship_mode
ADD CONSTRAINT ship_mode_pk PRIMARY KEY(sm_ship_mode_sk);


ALTER TABLE catalog_page
ADD CONSTRAINT catalog_page_pk PRIMARY KEY(cp_catalog_page_sk);


ALTER TABLE catalog_sales
ADD CONSTRAINT catalog_sales_pk PRIMARY KEY(cs_item_sk,cs_order_number);


ALTER TABLE web_site
ADD CONSTRAINT web_site_pk PRIMARY KEY(web_site_sk);


ALTER TABLE inventory
ADD CONSTRAINT inventory_pk PRIMARY KEY(inv_item_sk,inv_warehouse_sk,inv_date_sk);


ALTER TABLE item
ADD CONSTRAINT item_pk PRIMARY KEY(i_item_sk);


ALTER TABLE household_demographics
ADD CONSTRAINT household_demographics_pk PRIMARY KEY(hd_demo_sk);


ALTER TABLE web_sales
ADD CONSTRAINT web_sales_pk PRIMARY KEY(ws_order_number,ws_item_sk);


ALTER TABLE date_dim
ADD CONSTRAINT date_dim_pk PRIMARY KEY(d_date_sk);


ALTER TABLE customer_demographics
ADD CONSTRAINT customer_demographics_pk PRIMARY KEY(cd_demo_sk);


ALTER TABLE customer_address
ADD CONSTRAINT customer_address_pk PRIMARY KEY(ca_address_sk);